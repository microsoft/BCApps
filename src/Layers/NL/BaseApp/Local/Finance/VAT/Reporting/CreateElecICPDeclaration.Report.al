// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.Environment;
using System.Utilities;

report 11404 "Create Elec. ICP Declaration"
{
    Caption = 'Create Elec. ICP Declaration';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Elec. Tax Declaration Header"; "Elec. Tax Declaration Header")
        {
            DataItemTableView = sorting("Declaration Type", "No.") where("Declaration Type" = const("ICP Declaration"));
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(0 | 1 | 2));
                dataitem("VAT Entry"; "VAT Entry")
                {
                    DataItemTableView = sorting(Type, "Country/Region Code", "VAT Registration No.", "EU 3-Party Trade", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Calculation Type", "Document Type", "Posting Date") where(Type = const(Sale), "VAT Calculation Type" = const("Reverse Charge VAT"), "Document Type" = filter(Invoice | "Credit Memo"));
                    RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";

                    trigger OnAfterGetRecord()
                    var
                        CountryRegion: Record "Country/Region";
                        ElementName: Text[80];
                        CountryRegionCode: Code[10];
                    begin
                        TestField("VAT Registration No.");

                        SetRange("Country/Region Code", "Country/Region Code");
                        SetRange("VAT Registration No.", "VAT Registration No.");
                        CalcSums(Base);

                        if Abs(Base) >= 1 then begin
                            if CountryRegion.Get("Country/Region Code") then
                                CountryRegionCode := CountryRegion."EU Country/Region Code";
                            OnVATEntryOnAfterGetRecordOnGetCountryCode("VAT Entry");

                            if CountryRegionCode <> '' then begin
                                "Elec. Tax Declaration Header".InsertLine(0, 1, CurrentType, '');
                                InsertDataLine("Elec. Tax Declaration Header", 2, 'bd-i:CountryCodeISO-EC',
                                  CopyStr(CountryRegionCode, 1, 2), '', 'Msg', '');

                                if CopyStr(UpperCase("VAT Registration No."), 1, StrLen("Country/Region Code")) = CountryRegionCode then
                                    "VAT Registration No." := DelStr("VAT Registration No.", 1, StrLen("Country/Region Code"));

                                if Integer.Number = 1 then
                                    ElementName := 'bd-i:ServicesAmount'
                                else
                                    ElementName := 'bd-i:SuppliesAmount';

                                InsertDataLine("Elec. Tax Declaration Header", 2, ElementName,
                                  Format(-Base, 0, '<Sign><Integer>'), 'INF', 'Msg', 'EUR');
                                InsertDataLine("Elec. Tax Declaration Header", 2, 'bd-i:VATIdentificationNumberNational',
                                  "VAT Registration No.", '', 'Msg', '');
                            end;
                        end;

                        Find('+');
                        SetRange("Country/Region Code");
                        SetRange("VAT Registration No.");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(
                          "Posting Date",
                          "Elec. Tax Declaration Header"."Declaration Period From Date",
                          "Elec. Tax Declaration Header"."Declaration Period To Date");

                        case Integer.Number of
                            0:
                                begin
                                    SetRange("EU 3-Party Trade", false);
                                    SetRange("EU Service", false);
                                    CurrentType := 'bd-t:IntraCommunitySupplies';
                                end;
                            1:
                                begin
                                    SetRange("EU 3-Party Trade");
                                    SetRange("EU Service", true);
                                    CurrentType := 'bd-t:IntraCommunityServices';
                                end;
                            2:
                                begin
                                    SetRange("EU Service", false);
                                    SetRange("EU 3-Party Trade", true);
                                    CurrentType := 'bd-t:IntraCommunityABCSupplies';
                                end;
                        end;
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
                ApplicationSystemConstants: Codeunit "Application System Constants";
                ElecTaxDeclarationMgt: Codeunit "Elec. Tax Declaration Mgt.";
                UseVATRegNo: Text[20];
                ContactPrefix: Text[35];
            begin
                if Status > Status::Created then
                    Error(StatusErr);
                TestField("Our Reference");
                TestField("Declaration Year");
                TestField("Declaration Period");

                ElecTaxDeclarationHeader := "Elec. Tax Declaration Header";
                ElecTaxDeclarationHeader."Date Created" := Today;
                ElecTaxDeclarationHeader."Time Created" := Time;
                ElecTaxDeclarationHeader."Created By" := UserId();
                ElecTaxDeclarationHeader.Status := ElecTaxDeclarationHeader.Status::Created;
                ElecTaxDeclarationHeader."Schema Version" := ElecTaxDeclarationMgt.GetSchemaVersion();
                ElecTaxDeclarationHeader.Modify();

                UseVATRegNo := CompanyInfo.GetVATIdentificationNo(ElecTaxDeclarationSetup."Part of Fiscal Entity");

                ClearLines();

                InsertLine(0, 0, 'xbrli:xbrl', '');
                InsertLine(1, 1, 'xml:lang', 'nl');
                InsertLine(1, 1, 'xmlns:bd-t', ElecTaxDeclarationMgt.GetBDTuplesEndpoint());
                InsertLine(1, 1, 'xmlns:link', 'http://www.xbrl.org/2003/linkbase');
                InsertLine(1, 1, 'xmlns:bd-i', ElecTaxDeclarationMgt.GetBDDataEndpoint());
                InsertLine(1, 1, 'xmlns:iso4217', 'http://www.xbrl.org/2003/iso4217');
                InsertLine(1, 1, 'xmlns:xlink', 'http://www.w3.org/1999/xlink');
                InsertLine(1, 1, 'xmlns:xbrli', 'http://www.xbrl.org/2003/instance');

                // xbrli:xbrl->link:schemaRef
                InsertLine(0, 1, 'link:schemaRef', '');
                InsertLine(1, 2, 'xlink:type', 'simple');
                InsertLine(1, 2, 'xlink:href', ElecTaxDeclarationMgt.GetICPDeclarationSchemaEndpoint());

                // xbrli:xbrl->xbrli:context
                InsertLine(0, 1, 'xbrli:context', '');
                InsertLine(1, 2, 'id', 'Msg');

                // xbrli:xbrl->xbrli:context->xbrli:entity
                InsertLine(0, 2, 'xbrli:entity', '');
                InsertLine(0, 3, 'xbrli:identifier', UseVATRegNo);
                InsertLine(1, 4, 'scheme', 'www.belastingdienst.nl/omzetbelastingnummer');

                // xbrli:xbrl->xbrli:context->xbrli:period
                InsertLine(0, 2, 'xbrli:period', '');
                InsertLine(0, 3, 'xbrli:startDate', Format("Declaration Period From Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                InsertLine(0, 3, 'xbrli:endDate', Format("Declaration Period To Date", 0, '<Year4>-<Month,2>-<Day,2>'));

                // xbrli:xbrl->xbrli:unit
                InsertLine(0, 1, 'xbrli:unit', '');
                InsertLine(1, 2, 'id', 'EUR');
                InsertLine(0, 2, 'xbrli:measure', 'iso4217:EUR');

                // zbrli:xbrl->bd-i:VATIdentificationNumberNLFiscalEntityDivision
                if ElecTaxDeclarationSetup."Part of Fiscal Entity" then
                    InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:VATIdentificationNumberNLFiscalEntityDivision',
                      CompanyInfo.GetVATIdentificationNo(false), '', 'Msg', '');

                // zbrli:xbrl->bd-alg:Contact*
                if ElecTaxDeclarationSetup."ICP Contact Type" = ElecTaxDeclarationSetup."ICP Contact Type"::"Tax Payer" then begin
                    InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactInitials',
                      ExtractInitials(ElecTaxDeclarationSetup."Tax Payer Contact Name"), '', 'Msg', '');
                    ContactPrefix := ExtractNamePrefix(ElecTaxDeclarationSetup."Tax Payer Contact Name");
                    if ContactPrefix <> '' then
                        InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactPrefix', ContactPrefix, '', 'Msg', '');
                    InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactSurname',
                      ExtractSurname(ElecTaxDeclarationSetup."Tax Payer Contact Name"), '', 'Msg', '');
                    InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactTelephoneNumber',
                      ElecTaxDeclarationSetup."Tax Payer Contact Phone No.", '', 'Msg', '');
                end else begin
                    InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactInitials',
                      ExtractInitials(ElecTaxDeclarationSetup."Agent Contact Name"), '', 'Msg', '');
                    ContactPrefix := ExtractNamePrefix(ElecTaxDeclarationSetup."Agent Contact Name");
                    if ContactPrefix <> '' then
                        InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactPrefix', ContactPrefix, '', 'Msg', '');
                    InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactSurname',
                      ExtractSurname(ElecTaxDeclarationSetup."Agent Contact Name"), '', 'Msg', '');
                    InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactTelephoneNumber',
                      ElecTaxDeclarationSetup."Agent Contact Phone No.", '', 'Msg', '');
                    InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:TaxConsultantNumber',
                      ElecTaxDeclarationSetup."Agent Contact ID", '', 'Msg', '');
                end;

                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:DateTimeCreation',
                  FormatDateTime(ElecTaxDeclarationHeader."Date Created", ElecTaxDeclarationHeader."Time Created"), '', 'Msg', '');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:MessageReferenceSupplierICP', "Our Reference", '', 'Msg', '');

                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:SoftwarePackageVersion',
                  GetStrippedAppVersion(CopyStr(ApplicationSystemConstants.ApplicationVersion(), 3)), '', 'Msg', '');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:SoftwarePackageName', 'Microsoft Dynamics NAV', '', 'Msg', '');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:SoftwareVendorAccountNumber', 'SWO00638', '', 'Msg', '');
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField(Address);
        CompanyInfo.TestField("Post Code");
        CompanyInfo.TestField(City);
        CompanyInfo.TestField("VAT Registration No.");

        GLSetup.Get();
        GLSetup.TestField("Local Currency", GLSetup."Local Currency"::Euro);

        ElecTaxDeclarationSetup.Get();
        if ElecTaxDeclarationSetup."ICP Contact Type" = ElecTaxDeclarationSetup."ICP Contact Type"::Agent then begin
            ElecTaxDeclarationSetup.TestField("Agent Contact ID");
            ElecTaxDeclarationSetup.TestField("Agent Contact Name");
            ElecTaxDeclarationSetup.TestField("Agent Contact Address");
            ElecTaxDeclarationSetup.TestField("Agent Contact Post Code");
            ElecTaxDeclarationSetup.TestField("Agent Contact City");
            ElecTaxDeclarationSetup.TestField("Agent Contact Phone No.");
        end else begin
            ElecTaxDeclarationSetup.TestField("Tax Payer Contact Name");
            ElecTaxDeclarationSetup.TestField("Tax Payer Contact Phone No.");
        end;
        if ElecTaxDeclarationSetup."Part of Fiscal Entity" then
            CompanyInfo.TestField("Fiscal Entity No.");
    end;

    var
        CompanyInfo: Record "Company Information";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        StatusErr: Label 'The report status need to have value " " or Created to create the report content.';
        CurrentType: Text[60];

    local procedure GetStrippedAppVersion(AppVersion: Text[250]) Res: Text[250]
    begin
        Res := DelChr(AppVersion, '=', DelChr(AppVersion, '=', '0123456789'));
        exit(CopyStr(Res, 1, 2));
    end;

    local procedure InsertDataLine(var ElecTaxDeclHeader: Record "Elec. Tax Declaration Header"; Indentation: Integer; elementName: Text[80]; value: Text[250]; decimalType: Text[20]; contextRef: Text[20]; unitRef: Text[20])
    begin
        ElecTaxDeclHeader.InsertLine(0, Indentation, elementName, value);
        if decimalType <> '' then
            ElecTaxDeclHeader.InsertLine(1, Indentation + 1, 'decimals', decimalType);
        if contextRef <> '' then
            ElecTaxDeclHeader.InsertLine(1, Indentation + 1, 'contextRef', contextRef);
        if unitRef <> '' then
            ElecTaxDeclHeader.InsertLine(1, Indentation + 1, 'unitRef', unitRef);
    end;

    local procedure ExtractInitials(FullName: Text[35]) Initials: Text[30]
    var
        Pos: Integer;
    begin
        Pos := 1;
        Initials := '';
        Initials += CopyStr(FullName, 1, 1);
        while StrPos(FullName, ' ') <> 0 do begin
            FullName := CopyStr(FullName, StrPos(FullName, ' ') + 1);
            Initials += CopyStr(FullName, 1, 1);
        end;
    end;

    local procedure ExtractNamePrefix(FullName: Text[35]) Prefix: Text[35]
    begin
        if StrPos(FullName, ' ') > 1 then
            Prefix := CopyStr(FullName, 1, StrPos(FullName, ' ') - 1);
    end;

    local procedure ExtractSurname(FullName: Text[35]) Surname: Text[35]
    begin
        Surname := CopyStr(FullName, StrPos(FullName, ' ') + 1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVATEntryOnAfterGetRecordOnGetCountryCode(var VATEntry: Record "VAT Entry")
    begin
    end;
}

