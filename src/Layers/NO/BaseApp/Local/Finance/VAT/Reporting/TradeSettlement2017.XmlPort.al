// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;

xmlport 10618 "Trade Settlement 2017"
{
    Caption = 'Trade Settlement 2017';
    Direction = Export;
    Encoding = UTF8;

    schema
    {
        textelement(melding)
        {
            textattribute(dataFormatVersion)
            {

                trigger OnBeforePassVariable()
                begin
                    dataFormatVersion := '20160523';
                end;
            }
            textattribute(dataFormatProvider)
            {

                trigger OnBeforePassVariable()
                begin
                    dataFormatProvider := 'Skatteetaten';
                end;
            }
            textattribute(dataFormatId)
            {

                trigger OnBeforePassVariable()
                begin
                    dataFormatId := '212';
                end;
            }
            textelement(skattepliktig)
            {
                textelement(organisasjonsnummer)
                {

                    trigger OnBeforePassVariable()
                    begin
                        currXMLport.Skip();
                    end;
                }
                textelement(organisasjonsnavn)
                {

                    trigger OnBeforePassVariable()
                    begin
                        // Company Name
                        organisasjonsnavn := CompanyInformation.Name;
                    end;
                }
                textelement(kontonummer)
                {

                    trigger OnBeforePassVariable()
                    begin
                        currXMLport.Skip();
                    end;
                }
                textelement(KIDnummer)
                {

                    trigger OnBeforePassVariable()
                    begin
                        currXMLport.Skip();
                    end;
                }
                textelement(iban)
                {

                    trigger OnBeforePassVariable()
                    begin
                        iban := CompanyInformation.IBAN;
                    end;
                }
                textelement(swiftBic)
                {

                    trigger OnBeforePassVariable()
                    begin
                        swiftBic := CompanyInformation."SWIFT Code";
                    end;
                }
            }
            textelement(meldingsopplysning)
            {
                textelement(meldingstype)
                {

                    trigger OnBeforePassVariable()
                    begin
                        // 1 = Main, 2 = Additional, 3 = Correction
                        meldingstype := '1';
                    end;
                }
                textelement(termintype)
                {

                    trigger OnBeforePassVariable()
                    begin
                        // 1 = Yearly, 4 = BiMonthly, 5 = Monthly, 6 = HalfMonthly, 8 = Weekly
                        termintype := '4';
                    end;
                }
                textelement(termin)
                {
                }
                textelement(aar)
                {
                }
            }
            textelement(tilleggsopplysning)
            {
                textelement(forklaring)
                {
                }
                textelement(forklaringSendt)
                {
                }

                trigger OnBeforePassVariable()
                begin
                    currXMLport.Skip();
                end;
            }
            textelement(mvaSumAvgift)
            {
                textelement(aaBetale)
                {
                    MinOccurs = Zero;

                    trigger OnBeforePassVariable()
                    begin
                        if not PositiveVATSum then
                            currXMLport.Skip();
                    end;
                }
                textelement(tilGode)
                {
                    MinOccurs = Zero;

                    trigger OnBeforePassVariable()
                    begin
                        if PositiveVATSum then
                            currXMLport.Skip();
                    end;
                }
            }
            textelement(mvaAvgift)
            {
                textelement(box3vatamount)
                {
                    XmlName = 'innlandOmsetningUttakHoeySats';
                }
                textelement(box4vatamount)
                {
                    XmlName = 'innlandOmsetningUttakMiddelsSats';
                }
                textelement(box5vatamount)
                {
                    XmlName = 'innlandOmsetningUttakLavSats';
                }
                textelement(box9vatamount)
                {
                    XmlName = 'innfoerselVareHoeySats';
                }
                textelement(box10vatamount)
                {
                    XmlName = 'innfoerselVareMiddelsSats';
                }
                textelement(box12vatamount)
                {
                    XmlName = 'kjoepUtlandTjenesteHoeySats';
                }
                textelement(box13vatamount)
                {
                    XmlName = 'kjoepInnlandVareTjenesteHoeySats';
                }
                textelement(box14vatamount)
                {
                    XmlName = 'fradragInnlandInngaaendeHoeySats';
                }
                textelement(box15vatamount)
                {
                    XmlName = 'fradragInnlandInngaaendeMiddelsSats';
                }
                textelement(box16vatamount)
                {
                    XmlName = 'fradragInnlandInngaaendeLavSats';
                }
                textelement(box17vatamount)
                {
                    XmlName = 'fradragInnfoerselMvaHoeySats';
                }
                textelement(box18vatamount)
                {
                    XmlName = 'fradragInnfoerselMvaMiddelsSats';
                }
            }
            textelement(mvaGrunnlag)
            {
                textelement(box1vatbase)
                {
                    XmlName = 'sumOmsetningUtenforMva';
                }
                textelement(box2vatbase)
                {
                    XmlName = 'sumOmsetningInnenforMvaUttakOgInnfoersel';
                }
                textelement(box3vatbase)
                {
                    XmlName = 'innlandOmsetningUttakHoeySats';
                }
                textelement(box4vatbase)
                {
                    XmlName = 'innlandOmsetningUttakMiddelsSats';
                }
                textelement(box5vatbase)
                {
                    XmlName = 'innlandOmsetningUttakLavSats';
                }
                textelement(box6vatbase)
                {
                    XmlName = 'innlandOmsetningUttakFritattMva';
                }
                textelement(box7vatbase)
                {
                    XmlName = 'innlandOmsetningOmvendtAvgiftsplikt';
                }
                textelement(box8vatbase)
                {
                    XmlName = 'utfoerselVareTjenesteFritattMva';
                }
                textelement(box9vatbase)
                {
                    XmlName = 'innfoerselVareHoeySats';
                }
                textelement(box10vatbase)
                {
                    XmlName = 'innfoerselVareMiddelsSats';
                }
                textelement(box11vatbase)
                {
                    XmlName = 'innfoerselVareFritattMva';
                }
                textelement(box12vatbase)
                {
                    XmlName = 'kjoepUtlandTjenesteHoeySats';
                }
                textelement(box13vatbase)
                {
                    XmlName = 'kjoepInnlandVareTjenesteHoeySats';
                }
            }
            textelement(tjenesteType)
            {

                trigger OnBeforePassVariable()
                begin
                    currXMLport.Skip();
                end;
            }
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

    trigger OnInitXmlPort()
    begin
        CompanyInformation.Get();
    end;

    var
        CompanyInformation: Record "Company Information";
        PositiveVATSum: Boolean;

    [Scope('OnPrem')]
    procedure SetParameters(Year: Integer; VATPeriod: Integer; VATBase: array[19] of Decimal; VATAmount: array[19] of Decimal)
    begin
        aar := Format(Year);
        termin := '0' + Format(VATPeriod, 0, 9) + '4';

        PositiveVATSum := VATAmount[19] >= 0;
        if PositiveVATSum then
            aaBetale := Format(VATAmount[19], 0, 9)
        else
            tilGode := Format(-VATAmount[19], 0, 9);

        Box3VATAmount := Format(VATAmount[3], 0, 9);
        Box4VATAmount := Format(VATAmount[4], 0, 9);
        Box5VATAmount := Format(VATAmount[5], 0, 9);
        Box9VATAmount := Format(VATAmount[9], 0, 9);
        Box10VATAmount := Format(VATAmount[10], 0, 9);
        Box12VATAmount := Format(VATAmount[12], 0, 9);
        Box13VATAmount := Format(VATAmount[13], 0, 9);
        Box14VATAmount := Format(VATAmount[14], 0, 9);
        Box15VATAmount := Format(VATAmount[15], 0, 9);
        Box16VATAmount := Format(VATAmount[16], 0, 9);
        Box17VATAmount := Format(VATAmount[17], 0, 9);
        Box18VATAmount := Format(VATAmount[18], 0, 9);
        Box1VATBase := Format(VATBase[1], 0, 9);
        Box2VATBase := Format(VATBase[2], 0, 9);
        Box3VATBase := Format(VATBase[3], 0, 9);
        Box4VATBase := Format(VATBase[4], 0, 9);
        Box5VATBase := Format(VATBase[5], 0, 9);
        Box6VATBase := Format(VATBase[6], 0, 9);
        Box7VATBase := Format(VATBase[7], 0, 9);
        Box8VATBase := Format(VATBase[8], 0, 9);
        Box9VATBase := Format(VATBase[9], 0, 9);
        Box10VATBase := Format(VATBase[10], 0, 9);
        Box11VATBase := Format(VATBase[11], 0, 9);
        Box12VATBase := Format(VATBase[12], 0, 9);
        Box13VATBase := Format(VATBase[13], 0, 9);
    end;
}

