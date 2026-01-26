// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;

codeunit 11110 "Update VAT-AT"
{

    trigger OnRun()
    begin
    end;

    var
        DeleteVATStatementQst: Label 'Do you want to delete the existing VAT Statement Template %1 and create a new one?', Comment = '%1 = Template Name';
        CreateVATStatementQst: Label 'Do you want to create a new VAT Statement Template %1?', Comment = '%1 = Template Name';
        TemplateUpdatedMsg: Label 'The VAT Statement Template %1 has been successfully updated or created.', Comment = '%1 = Template Name';
        NoTemplateUpdatedErr: Label 'No VAT Statement Template has been created or updated.';
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        LineNo: Integer;
        VATStatementNameTxt: Label 'DEFAULT', Comment = 'VAT Statement Name';
        KZ0009Txt: Label '  5% Base Amount for revenue for Par.28 Sec.52 N.1', Comment = 'Must be up to 50 characters in total with 2 leading spaces. Paragraph 28 Section 52 Number 1.';
        KZ1009Txt: Label '  5% Tax Amount for revenue for Par.28 Sec.52 N.1', Comment = 'Must be up to 50 characters in total with 2 leading spaces. Paragraph 28 Section 52 Number 1.';

    [Scope('OnPrem')]
    procedure UpdateVATStatementTemplate(TemplateName: Code[10]; TemplateDescription: Text[80]; AgricultureVATProdPostingGroups: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateVATStatementTemplate(TemplateName, IsHandled);
        if IsHandled then
            exit;

        if VATStatementTemplate.Get(TemplateName) then begin
            if not Confirm(DeleteVATStatementQst, true, TemplateName) then
                Error(NoTemplateUpdatedErr)
        end else
            if not Confirm(CreateVATStatementQst, true, TemplateName) then
                Error(NoTemplateUpdatedErr);

        Update(TemplateName, TemplateDescription, AgricultureVATProdPostingGroups);

        Message(TemplateUpdatedMsg, VATStatementTemplate.Name);
    end;

    [Scope('OnPrem')]
    procedure Update(TemplateName: Code[10]; TemplateDescription: Text[80]; AgricultureVATProdPostingGroups: Text)
    begin
        if VATStatementTemplate.Get(TemplateName) then
            VATStatementTemplate.Delete(true);

        VATStatementTemplate.Init();
        VATStatementTemplate.Name := TemplateName;
        VATStatementTemplate.Description := TemplateDescription;
        VATStatementTemplate."VAT Statement Report ID" := REPORT::"VAT Statement AT";
        VATStatementTemplate."Page ID" := PAGE::"VAT Statement";
        VATStatementTemplate.Insert();

        VATStatementName.Init();
        VATStatementName."Statement Template Name" := TemplateName;
        VATStatementName.Name := VATStatementNameTxt;
        VATStatementName.Insert();
        LineNo := 10000;

        InsertSalestaxBaseamounts(AgricultureVATProdPostingGroups);
        InsertSalestaxAmounts(AgricultureVATProdPostingGroups);
        InsertPurchasetaxBaseamounts(AgricultureVATProdPostingGroups);
        InsertPurchasetaxAmounts(AgricultureVATProdPostingGroups);
        InsertEUTaxBaseamounts(AgricultureVATProdPostingGroups);
        InsertEUTaxAmounts(AgricultureVATProdPostingGroups);
        InsertEUShipments();
        InsertRownumbers();
    end;

    local procedure InsertSalestaxBaseamounts(AgricultureVATProdPostingGroups: Text)
    begin
        InsertData('', 'UST Bemessungsgrundlagen', 3, 0, 0, '', false, false);

        CreateVATStatementLines('BU', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BU', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BU', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 13,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BU', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 5,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BU', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);

        CreateVATStatementLines('BU', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 19,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);

        CreateVATStatementLines('BU', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 7,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, true, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BU', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, true, AgricultureVATProdPostingGroups);
    end;

    local procedure InsertSalestaxAmounts(AgricultureVATProdPostingGroups: Text)
    begin
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'UST Beträge', 3, 0, 0, '', false, false);

        CreateVATStatementLines('UST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('UST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('UST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 13,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('UST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 5,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('UST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);

        CreateVATStatementLines('UST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 19,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);

        CreateVATStatementLines('UST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 7,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, true, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('UST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, true, AgricultureVATProdPostingGroups);
    end;

    local procedure InsertPurchasetaxBaseamounts(AgricultureVATProdPostingGroups: Text)
    begin
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Vorsteuer Bemessungsgrundlagen', 3, 0, 0, '', false, false);

        CreateVATStatementLines('BV', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BV', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BV', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 13,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BV', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 5,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BV', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);

        CreateVATStatementLines('BV', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 19,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
    end;

    local procedure InsertPurchasetaxAmounts(AgricultureVATProdPostingGroups: Text)
    begin
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Vorsteuer Beträge', 3, 0, 0, '', false, false);

        CreateVATStatementLines('VST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('VST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('VST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 13,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('VST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 5,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('VST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);

        CreateVATStatementLines('VST', VATPostingSetup."VAT Calculation Type"::"Normal VAT", 19,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
    end;

    local procedure InsertEUTaxBaseamounts(AgricultureVATProdPostingGroups: Text)
    begin
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Erwerbsteuer Bemessungsgrundlagen', 3, 0, 0, '', false, false);

        CreateVATStatementLines('BES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 20,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 10,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 13,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 5,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('BES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 0,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);

        CreateVATStatementLines('BES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 19,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, false, AgricultureVATProdPostingGroups);
    end;

    local procedure InsertEUTaxAmounts(AgricultureVATProdPostingGroups: Text)
    begin
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Erwerbsteuer Beträge', 3, 0, 0, '', false, false);

        CreateVATStatementLines('ES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 20,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('ES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 10,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('ES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 13,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('ES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 5,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
        CreateVATStatementLines('ES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 0,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);

        CreateVATStatementLines('ES', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 19,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, false, AgricultureVATProdPostingGroups);
    end;

    local procedure InsertEUShipments()
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.SetRange("VAT %");
        if VATPostingSetup.FindSet() then begin
            InsertData('', '', 3, 0, 0, '', false, false);
            InsertData('', 'Lieferungen in die EU', 3, 0, 0, '', false, false);
            repeat
                InsertData(
                  'EULIEF',
                  CopyStr('   ' + VATPostingSetup."VAT Bus. Posting Group" + ' / ' + VATPostingSetup."VAT Prod. Posting Group", 1, 50),
                  1, VATStatementLine."Gen. Posting Type"::Sale.AsInteger(), VATStatementLine."Amount Type"::Base.AsInteger(), '', false, true);
            until VATPostingSetup.Next() = 0;
        end;
    end;

    local procedure InsertRownumbers()
    begin
        VATStatementLine."VAT Bus. Posting Group" := '';
        VATStatementLine."VAT Prod. Posting Group" := '';
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'POS.NUMMERN FÜR UVA-FORMULAR', 3, 0, 0, '', false, false);
        InsertData('', '  Bemessungsgrundlagen beginnen mit 0xxx', 3, 0, 0, '', false, false);
        InsertData('', '  UST Beträgebeginnen mit 1xxx', 3, 0, 0, '', false, false);
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Lieferungen, sonstige Leist. und Eigenverbrauch:', 3, 0, 0, '', false, false);
        InsertData(
          '1000', '  BMG für Lief. und Leist. inkl. Anzahlungen', 2, 0, 0, 'BU20|BU10|BU13|BU19|BULW10|BULW7|BU0|BU5|EULIEF', true, false);
        InsertData('1001', '  zuzüglich Eigenverbrauch', 2, 0, 0, '', true, false);
        InsertData('1021', '  abzüglich Umsätze Art. 19', 2, 0, 0, '', true, false);
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Davon steuerfrei MIT Vorsteuerabzug gemäß', 3, 0, 0, '', false, false);
        InsertData('1011', '  Art. 6 Ausfuhrlieferungen', 2, 0, 0, 'BU0', true, false);
        InsertData('1012', '  Art. 6 Lohnveredelung', 2, 0, 0, '', true, false);
        InsertData('1015', '  Art. 6 Seeschifffahrt usw.', 2, 0, 0, '', true, false);
        InsertData('1017', '  Art. 6 innerg. Lieferungen', 2, 0, 0, 'EULIEF', true, false);
        InsertData('1018', '  Art. 6 Fahrzeuge ohne UID', 2, 0, 0, '', true, false);
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Davon steuerfrei OHNE Vorsteuerabzug gemäß', 3, 0, 0, '', false, false);
        InsertData('1019', '  Art. 6 Grundstücksumsätze', 2, 0, 0, '', true, false);
        InsertData('1016', '  Art. 6 Kleinunternehmer', 2, 0, 0, '', true, false);
        InsertData('1020', '  Art. 6 übrige Umsätze', 2, 0, 0, '', true, false);
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Davon sind zu versteuern mit:', 3, 0, 0, '', false, false);
        InsertData('0022', '  20% BMG Normalsteuersatz', 2, 0, 0, 'BU20', true, false);
        InsertData('1022', '  20% UST Normalsteuersatz', 2, 0, 0, 'UST20', true, false);
        InsertData('0029', '  10% BMG ermäßigter Steuersatz', 2, 0, 0, 'BU10', true, false);
        InsertData('1029', '  10% UST ermäßigter Steuersatz', 2, 0, 0, 'UST10', true, false);
        InsertData('0006', '  13% BMG ermäßigter Steuersatz', 2, 0, 0, 'BU13', true, false);
        InsertData('1006', '  13% UST ermäßigter Steuersatz', 2, 0, 0, 'UST13', true, false);
        InsertData('0037', '  19% BMG Jungholz und Mittelberg', 2, 0, 0, 'BU19', true, false);
        InsertData('1037', '  19% UST Jungholz und Mittelberg', 2, 0, 0, 'UST19', true, false);
        InsertData('0052', '  10% BMG pauschalierte LW', 2, 0, 0, 'BULW10', true, false);
        InsertData('1052', '  10% UST pauschalierte LW', 2, 0, 0, 'USLWT10', true, false);
        InsertData('0007', '  7% BMG pauschalierte LW', 2, 0, 0, 'BULW7', true, false);
        InsertData('1007', '  7% UST pauschalierte LW', 2, 0, 0, 'USLWT7', true, false);
        InsertData('0009', CopyStr(KZ0009Txt, 1, 50), 2, 0, 0, 'BU5', true, false);
        InsertData('1009', CopyStr(KZ1009Txt, 1, 50), 2, 0, 0, 'UST5', true, false);
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Weiters zu versteuern:', 3, 0, 0, '', false, false);
        InsertData('1056', '  Steuerschuld Art. 11', 2, 0, 0, '', true, false);
        InsertData('1057', '  Steuerschuld Art. 19', 2, 0, 0, '', true, false);
        InsertData('1048', '  Steuerschuld Art. 19 (Bauleistungen)', 2, 0, 0, '', true, false);
        InsertData('1044', '  Steuerschuld Art. 19 (Sicherungseigentum)', 2, 0, 0, '', true, false);
        InsertData('1032', '  Steuerschuld Art. 19 (Schrott und Abfall)', 2, 0, 0, '', true, false);
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Innergemeinschaftliche Erwerbe:', 3, 0, 0, '', false, false);
        InsertData('0070', '  BMG Innerg. Erwerbe', 2, 0, 0, 'BES20|BES10|BES13|BES19|BES0|BES5', true, false);
        InsertData('0071', '  Davon steuerfrei gem. Art.6 Abs. 2', 2, 0, 0, 'BES0', true, false);
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Davon sind zu versteuern mit:', 3, 0, 0, '', false, false);
        InsertData('0072', '  20% BMG Normalsteuersatz', 2, 0, 0, 'BES20', true, false);
        InsertData('1072', '  20% UST Normalsteuersatz', 2, 0, 0, 'ES20', true, false);
        InsertData('0073', '  10% BMG ermäßigter Steuersatz', 2, 0, 0, 'BES10', true, false);
        InsertData('1073', '  10% UST ermäßigter Steuersatz', 2, 0, 0, 'ES10', true, false);
        InsertData('0008', '  13% BMG ermäßigter Steuersatz', 2, 0, 0, 'BES13', true, false);
        InsertData('1008', '  13% UST ermäßigter Steuersatz', 2, 0, 0, 'ES13', true, false);
        InsertData('0088', '  19% BMG für Jungholz und Mittelberg', 2, 0, 0, 'BES19', true, false);
        InsertData('1088', '  19% UST für Jungholz und Mittelberg', 2, 0, 0, 'ES19', true, false);
        InsertData('0010', CopyStr(KZ0009Txt, 1, 50), 2, 0, 0, 'BES5', true, false);
        InsertData('1010', CopyStr(KZ1009Txt, 1, 50), 2, 0, 0, 'ES5', true, false);
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Nicht zu versteuernde Erwerbe:', 3, 0, 0, '', false, false);
        InsertData('0076', '  Erwerbe Art.3 Abs.8 (1)', 2, 0, 0, '', true, false);
        InsertData('0077', '  Erwerbe Art.3 Abs.8 (2)', 2, 0, 0, '', true, false);
        InsertData('', '', 3, 0, 0, '', false, false);
        InsertData('', 'Berechnung der abziehbaren Vorsteuer:', 3, 0, 0, '', false, false);
        InsertData('1060', '  Gesamtbetrag der Vorsteuern', 2, 0, 0, 'VST20|VST10|VST13|VST19|VST5', true, false);
        InsertData('1061', '  Einfuhrumsatzsteuer', 2, 0, 0, '', true, false);
        InsertData('1083', '  Vorsteuern Art. 12 Abs.1 Z 2 lit.b', 2, 0, 0, '', true, false);
        InsertData('1065', '  Vorsteuern aus dem Innerg. Erwerb', 2, 0, 0, 'ES20|ES10|ES13|ES19|ES5', true, false);
        InsertData('1066', '  Vorsteuern Art. 19', 2, 0, 0, '', true, false);
        InsertData('1082', '  Vorsteuern Art. 19 (Bauleistungen)', 2, 0, 0, '', true, false);
        InsertData('1087', '  Vorsteuern Art. 19 (Sicherungseigentum)', 2, 0, 0, '', true, false);
        InsertData('1089', '  Vorsteuern Art. 19 (Schrott und Abfall)', 2, 0, 0, '', true, false);
        InsertData('1064', '  Vorsteuern Art. 12', 2, 0, 0, '', true, false);
        InsertData('1062', '  davon nicht abzugsfähig gem. Art. 12', 2, 0, 0, '', true, false);
        InsertData('1063', '  Berichtigung gem. Art. 12', 2, 0, 0, '', true, false);
        InsertData('1067', '  Berichtigung gem. Art. 16', 2, 0, 0, '', true, false);
        InsertData('1090', '  Sonstige Berichtigungen', 2, 0, 0, '', true, false);
    end;

    local procedure InsertData(RowNo: Code[10]; Description: Text[50]; Type: Option; GenPostingType: Option; AmountType: Option; RowTotaling: Text[250]; Print: Boolean; ReverseSign: Boolean)
    begin
        VATStatementLine.Init();
        VATStatementLine."Statement Template Name" := VATStatementTemplate.Name;
        VATStatementLine."Statement Name" := VATStatementNameTxt;
        VATStatementLine."Line No." := LineNo;
        LineNo := LineNo + 10000;

        VATStatementLine."Row No." := RowNo;
        VATStatementLine.Description := Description;
        VATStatementLine.Type := "VAT Statement Line Type".FromInteger(Type);
        VATStatementLine."Gen. Posting Type" := "General Posting Type".FromInteger(GenPostingType);
        VATStatementLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStatementLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStatementLine."Amount Type" := "VAT Statement Line Amount Type".FromInteger(AmountType);
        VATStatementLine."Row Totaling" := RowTotaling;
        VATStatementLine.Print := Print;
        if ReverseSign then
            VATStatementLine."Calculate with" := VATStatementLine."Calculate with"::"Opposite Sign"
        else
            VATStatementLine."Calculate with" := VATStatementLine."Calculate with"::Sign;
        if (RowNo = '') or (VATStatementLine.Type = VATStatementLine.Type::"Row Totaling") then begin
            VATStatementLine."VAT Bus. Posting Group" := '';
            VATStatementLine."VAT Prod. Posting Group" := '';
        end;
        VATStatementLine.Insert();
    end;

    local procedure CreateVATStatementLines(RowNoPrefix: Text; VATCalculationType: Enum "Tax Calculation Type"; VATPercentage: Integer; GenPostingType: Enum "General Posting Type"; AmountType: Enum "VAT Statement Line Amount Type"; IsAgriculture: Boolean; AgricultureVATProdPostingGroups: Text)
    begin
        if IsAgriculture and (AgricultureVATProdPostingGroups = '') then
            exit;

        if IsAgriculture then
            RowNoPrefix += 'LW';

        VATPostingSetup.SetRange("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.SetRange("VAT %", VATPercentage);
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", GetFilterString(IsAgriculture, AgricultureVATProdPostingGroups));
        if VATPostingSetup.FindSet() then
            repeat
                InsertData(
                  RowNoPrefix + Format(VATPercentage),
                  CopyStr('   ' + VATPostingSetup."VAT Bus. Posting Group" + ' / ' + VATPostingSetup."VAT Prod. Posting Group", 1, 50),
                  1, GenPostingType.AsInteger(), AmountType.AsInteger(), '', false, GenPostingType = VATStatementLine."Gen. Posting Type"::Sale);
            until VATPostingSetup.Next() = 0;
    end;

    local procedure GetFilterString(IsAgriculture: Boolean; AgricultureVATProdPostingGroups: Text): Text
    begin
        if AgricultureVATProdPostingGroups = '' then
            exit('');

        if IsAgriculture then
            exit(AgricultureVATProdPostingGroups);

        // Invert Filter
        exit('<>' + ConvertString(AgricultureVATProdPostingGroups, '|', '&<>'));
    end;

    local procedure ConvertString(var TextString: Text; FromCharacters: Text; ToCharacters: Text): Text
    var
        Position: Integer;
    begin
        while StrPos(TextString, FromCharacters) <> 0 do begin
            Position := StrPos(TextString, FromCharacters);
            TextString := DelStr(TextString, Position, StrLen(FromCharacters));
            TextString := InsStr(TextString, ToCharacters, Position);
        end;
        exit(TextString);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATStatementTemplate(TemplateName: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

