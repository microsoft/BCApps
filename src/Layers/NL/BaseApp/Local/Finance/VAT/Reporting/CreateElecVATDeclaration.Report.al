// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using System.Environment;

report 11403 "Create Elec. VAT Declaration"
{
    Caption = 'Create Elec. VAT Declaration';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Elec. Tax Declaration Header"; "Elec. Tax Declaration Header")
        {
            DataItemTableView = sorting("Declaration Type", "No.") where("Declaration Type" = const("VAT Declaration"));

            trigger OnAfterGetRecord()
            var
                ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
                UseVATRegNo: Text[20];
            begin
                if Status > Status::Created then
                    Error(StatusErr);
                TestField("Our Reference");
                TestField("Declaration Period");
                TestField("Declaration Year");

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
                InsertLine(1, 1, 'xmlns:link', 'http://www.xbrl.org/2003/linkbase');
                InsertLine(1, 1, 'xmlns:bd-i', ElecTaxDeclarationMgt.GetBDDataEndpoint());
                InsertLine(1, 1, 'xmlns:iso4217', 'http://www.xbrl.org/2003/iso4217');
                InsertLine(1, 1, 'xmlns:xbrli', 'http://www.xbrl.org/2003/instance');
                InsertLine(1, 1, 'xmlns:xlink', 'http://www.w3.org/1999/xlink');

                // xbrli:xbrl->link:schemaRef
                InsertLine(0, 1, 'link:schemaRef', '');
                InsertLine(1, 2, 'xlink:type', 'simple');
                InsertLine(1, 2, 'xlink:href', ElecTaxDeclarationMgt.GetVATDeclarationSchemaEndpoint());

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

                case ElecTaxDeclarationSetup."VAT Contact Type" of
                    ElecTaxDeclarationSetup."VAT Contact Type"::"Tax Payer":
                        begin
                            InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactInitials',
                              ExtractInitials(ElecTaxDeclarationSetup."Tax Payer Contact Name"), '', 'Msg', '');
                            InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactPrefix',
                              ExtractNamePrefix(ElecTaxDeclarationSetup."Tax Payer Contact Name"), '', 'Msg', '');
                            InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactSurname',
                              ExtractSurname(ElecTaxDeclarationSetup."Tax Payer Contact Name"), '', 'Msg', '');
                            InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactTelephoneNumber',
                              ElecTaxDeclarationSetup."Tax Payer Contact Phone No.", '', 'Msg', '');
                        end;
                    ElecTaxDeclarationSetup."VAT Contact Type"::Agent:
                        begin
                            InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactInitials',
                              ExtractInitials(ElecTaxDeclarationSetup."Agent Contact Name"), '', 'Msg', '');
                            InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactPrefix',
                              ExtractNamePrefix(ElecTaxDeclarationSetup."Agent Contact Name"), '', 'Msg', '');
                            InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactSurname',
                              ExtractSurname(ElecTaxDeclarationSetup."Agent Contact Name"), '', 'Msg', '');
                            InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactTelephoneNumber',
                              ElecTaxDeclarationSetup."Agent Contact Phone No.", '', 'Msg', '');
                            InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:TaxConsultantNumber',
                              ElecTaxDeclarationSetup."Agent Contact ID", '', 'Msg', '');
                        end;
                end;
                case ElecTaxDeclarationSetup."VAT Contact Type" of
                    ElecTaxDeclarationSetup."VAT Contact Type"::"Tax Payer":
                        InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactType', 'BPL', '', 'Msg', '');
                    ElecTaxDeclarationSetup."VAT Contact Type"::Agent:
                        InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ContactType', 'INT', '', 'Msg', '');
                end;

                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:DateTimeCreation',
                  FormatDateTime(ElecTaxDeclarationHeader."Date Created", ElecTaxDeclarationHeader."Time Created"), '', 'Msg', '');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:InstallationDistanceSalesWithinTheEC',
                  CalcVATAmount(9, 9), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:MessageReferenceSupplierVAT', "Our Reference", '', 'Msg', '');

                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:SoftwarePackageName', 'Microsoft Dynamics NAV', '', 'Msg', '');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:SoftwarePackageVersion',
                  GetStrippedAppVersion(CopyStr(ApplicationSystemConstants.ApplicationVersion(), 3)), '', 'Msg', '');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:SoftwareVendorAccountNumber', 'SWO00638', '', 'Msg', '');

                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:SuppliesServicesNotTaxed', CalcVATAmount(3, 27), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:SuppliesToCountriesOutsideTheEC', CalcVATAmount(9, 3), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:SuppliesToCountriesWithinTheEC', CalcVATAmount(9, 6), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:TaxedTurnoverPrivateUse', CalcVATAmount(3, 21), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:TaxedTurnoverSuppliesServicesGeneralTariff',
                  CalcVATAmount(3, 3), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:TaxedTurnoverSuppliesServicesOtherRates',
                  CalcVATAmount(3, 15), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:TaxedTurnoverSuppliesServicesReducedTariff',
                  CalcVATAmount(3, 9), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:TurnoverFromTaxedSuppliesFromCountriesOutsideTheEC',
                  CalcVATAmount(12, 3), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:TurnoverFromTaxedSuppliesFromCountriesWithinTheEC',
                  CalcVATAmount(12, 9), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:TurnoverSuppliesServicesByWhichVATTaxationIsTransferred',
                  CalcVATAmount(6, 3), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ValueAddedTaxOnInput', CalcVATAmount(18, 6), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ValueAddedTaxOnSuppliesFromCountriesOutsideTheEC',
                  CalcVATAmount(12, 6), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ValueAddedTaxOnSuppliesFromCountriesWithinTheEC',
                  CalcVATAmount(12, 12), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ValueAddedTaxOwed', CalcVATAmount(18, 3), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ValueAddedTaxOwedToBePaidBack', CalcVATAmount(18, 18), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ValueAddedTaxPrivateUse', CalcVATAmount(3, 24), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ValueAddedTaxSuppliesServicesByWhichVATTaxationIsTransferred',
                  CalcVATAmount(6, 6), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ValueAddedTaxSuppliesServicesGeneralTariff',
                  CalcVATAmount(3, 6), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ValueAddedTaxSuppliesServicesOtherRates',
                  CalcVATAmount(3, 18), 'INF', 'Msg', 'EUR');
                InsertDataLine("Elec. Tax Declaration Header", 1, 'bd-i:ValueAddedTaxSuppliesServicesReducedTariff',
                  CalcVATAmount(3, 12), 'INF', 'Msg', 'EUR');
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(VATTemplateName; VATTemplateName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Template Name';
                        TableRelation = "VAT Statement Template";
                        ToolTip = 'Specifies the name of the VAT template.';

                        trigger OnValidate()
                        begin
                            VATStmtName := '';
                        end;
                    }
                    field(VATStatementName; VATStmtName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statement Name';
                        ToolTip = 'Specifies the name of the VAT statement.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            VATStatementName: Record "VAT Statement Name";
                        begin
                            VATStatementName.FilterGroup(4);
                            VATStatementName.SetRange("Statement Template Name", VATTemplateName);
                            VATStatementName.FilterGroup(0);

                            if PAGE.RunModal(0, VATStatementName) = ACTION::LookupOK then
                                VATStmtName := VATStatementName.Name;
                        end;

                        trigger OnValidate()
                        var
                            VATStatementName: Record "VAT Statement Name";
                        begin
                            if VATStmtName <> '' then begin
                                VATStatementName.SetRange("Statement Template Name", VATTemplateName);
                                VATStatementName.SetFilter(Name, VATStmtName + '*');
                                VATStatementName.FindFirst();
                                VATStmtName := VATStatementName.Name;
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ElecTaxDeclarationSetup.Get();

        if ElecTaxDeclarationSetup."VAT Contact Type" = ElecTaxDeclarationSetup."VAT Contact Type"::Agent then begin
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

        CompanyInfo.Get();
        CompanyInfo.TestField("VAT Registration No.");

        if ElecTaxDeclarationSetup."Part of Fiscal Entity" then begin
            CompanyInfo.TestField("Fiscal Entity No.");
            Message(Text001);
        end;

        GLSetup.Get();
        GLSetup.TestField("Local Currency", GLSetup."Local Currency"::Euro);
    end;

    trigger OnPreReport()
    begin
        if (VATTemplateName = '') or (VATStmtName = '') then
            Error(Text000);
    end;

    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        ApplicationSystemConstants: Codeunit "Application System Constants";
        ElecTaxDeclarationMgt: Codeunit "Elec. Tax Declaration Mgt.";
        VATTemplateName: Code[10];
        VATStmtName: Code[10];
        Text000: Label 'Please specify a VAT Template Name and a VAT Statement Name.';
        Text001: Label 'It is only possible to create an Electronic VAT Declaration for one company. If more companies belong to this Fiscal Entity, please submit the VAT details via the Tax Authority website.';
        StatusErr: Label 'The report must have the status of " " or Created before you can create the report content.';

    local procedure CalcVATAmount(Category: Integer; SubCategory: Integer): Text[30]
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
        VATStatement: Report "VAT Statement";
        CategoryCode: Code[10];
        Value: Decimal;
    begin
        CategoryCode := ElecTaxDeclVATCategory.GetCategoryCode(Category, SubCategory);
        ElecTaxDeclVATCategory.Get(CategoryCode);

        VATStatementLine.SetRange("Statement Template Name", VATTemplateName);
        VATStatementLine.SetRange("Statement Name", VATStmtName);
        VATStatementLine.SetRange("Elec. Tax Decl. Category Code", CategoryCode);

        case ElecTaxDeclVATCategory.Optional of
            true:
                if not VATStatementLine.FindFirst() then
                    exit('0');
            false:
                VATStatementLine.FindFirst();
        end;

        VATStatementName.Get(VATTemplateName, VATStmtName);

        VATStatementLine.SetRange("Date Filter",
          "Elec. Tax Declaration Header"."Declaration Period From Date", "Elec. Tax Declaration Header"."Declaration Period To Date");
        VATStatement.SetElectronicVAT(true);
        VATStatement.InitializeRequest(
          VATStatementName, VATStatementLine, "VAT Statement Report Selection"::Open,
          "VAT Statement Report Period Selection"::"Within Period", true, false);
        VATStatement.CalcLineTotal(VATStatementLine, Value, 0);

        if VATStatementLine."Print with" = VATStatementLine."Print with"::"Opposite Sign" then
            Value := -Value;

        exit(Format(Value, 0, '<Sign><Integer>'));
    end;

    local procedure GetStrippedAppVersion(AppVersion: Text[250]) Res: Text[250]
    begin
        Res := DelChr(AppVersion, '=', DelChr(AppVersion, '=', '0123456789'));
        exit(CopyStr(Res, 1, 2));
    end;

    local procedure InsertDataLine(var ElecTaxDeclHeader: Record "Elec. Tax Declaration Header"; Indentation: Integer; elementName: Text; value: Text; decimalType: Text; contextRef: Text; unitRef: Text)
    begin
        ElecTaxDeclHeader.InsertLine(0, Indentation, elementName, value);
        if decimalType <> '' then
            ElecTaxDeclHeader.InsertLine(1, Indentation + 1, 'decimals', decimalType);
        if contextRef <> '' then
            ElecTaxDeclHeader.InsertLine(1, Indentation + 1, 'contextRef', contextRef);
        if unitRef <> '' then
            ElecTaxDeclHeader.InsertLine(1, Indentation + 1, 'unitRef', unitRef);
    end;

    local procedure ExtractInitials(FullName: Text) Initials: Text
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

    local procedure ExtractNamePrefix(FullName: Text) Prefix: Text
    begin
        if StrPos(FullName, ' ') > 1 then
            Prefix := CopyStr(FullName, 1, StrPos(FullName, ' ') - 1);
    end;

    local procedure ExtractSurname(FullName: Text[35]) Surname: Text[35]
    begin
        Surname := CopyStr(FullName, StrPos(FullName, ' ') + 1)
    end;
}

