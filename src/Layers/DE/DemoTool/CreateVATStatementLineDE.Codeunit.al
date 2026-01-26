codeunit 161405 "Create VAT Statement Line - DE"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('', 'MEHRWERTSTEUERABRECHNUNG', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('41', '41B1 / Steuerfreie Erlöse §4 1b UStG EG m. ID-Nr.', 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 1, false);
        InsertData('41', '41B2 / Steuerfreie Erlöse §4 1b UStG EG m. ID-Nr.', 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('43', '43B1 / Stfr. Umsätze m. VorSt-Abzug §4 2-7 UStG', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 1, false);
        InsertData('43', '43B2 / Stfr. Umsätze m. VorSt-Abzug §4 2-7 UStG', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('81A', StrSubstNo('81B / Stpfl. Umsätze %1', DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 1, false);
        InsertData('81S', StrSubstNo('81S / Umsatzsteuer %1', DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 1, false);
        InsertData('50A', '50 / Minderung Bmg 19%', 1, '', 2, DemoDataSetup.DomesticCode(), MIN19Code(), '', 2, 0, true, 1, false);
        InsertData('50AS', '50 / Minderung Betr 19%', 1, '', 2, DemoDataSetup.DomesticCode(), MIN19Code(), '', 1, 0, true, 1, false);
        InsertData('81', '81B / Stpfl. Umsätze 19 %', 2, '', 0, '', '', '81A|50A', 0, 0, true, 1, false);
        InsertData('81ST', '81S / Umsatzsteuer 19 %', 2, '', 0, '', '', '81S|50AS', 0, 0, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('86A', StrSubstNo('86B / Stpfl. Umsätze %1', DemoDataSetup.ServicesVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 1, false);
        InsertData('86S', StrSubstNo('86S / Umsatzsteuer %1', DemoDataSetup.ServicesVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 1, false);
        InsertData('87', '87 / Stpfl. Umsätze 0%', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, true, 1, false);
        InsertData('50B', '50 / Minderung Bmg 7%', 1, '', 2, DemoDataSetup.DomesticCode(), MIN7Code(), '', 2, 0, true, 1, false);
        InsertData('50BS', '50 / Minderung Betr 7%', 1, '', 2, DemoDataSetup.DomesticCode(), MIN7Code(), '', 1, 0, true, 1, false);
        InsertData('86', '886B / Stpfl. Umsätze 7 %', 2, '', 0, '', '', '86A|50B', 0, 0, true, 1, false);
        InsertData('86ST', '86S / Umsatzsteuer 7 %', 2, '', 0, '', '', '86S|50BS', 0, 0, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('50', '50 / Minderung Bmg 19%', 1, '', 2, DemoDataSetup.DomesticCode(), MIN19Code(), '', 2, 1, true, 1, false);
        InsertData('50', '50 / Minderung Bmg 7%', 1, '', 2, DemoDataSetup.DomesticCode(), MIN7Code(), '', 2, 1, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('36', '36 / Umsätze zu anderen Steuersätzen', 0, '', 2, DemoDataSetup.DomesticCode(), '', '', 2, 0, true, 1, false);
        InsertData('35', '35 / Steuer aus Umsätze zu anderen Steuersätzen', 0, '', 2, DemoDataSetup.DomesticCode(), '', '', 1, 0, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('91', '91 / Innergem. Erwerbe § 4b UStG', 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.NoVATCode(), '', 2, 1, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData(
          '89', StrSubstNo('89B / Stpfl. innergem. Erwerbe %1 n. §1a UStG', DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 1, true, 1,
          false);
        InsertData('89', StrSubstNo('89S / Erwerbsteuer %1 n. §1a UStG', DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 1, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData(
          '93', StrSubstNo('93B / Stpfl. innergem. Erwerbe %1 n. §1a UStG', DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 1, true, 1,
          false);
        InsertData(
          '93', StrSubstNo('93S / Erwerbsteuer %1 n. §1a UStG', DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 1, true, 1, false);
        InsertData('90', '90 / Stpfl. innergem. Erwerbe 0%', 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.NoVATCode(), '', 2, 0, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('66A', '66S1 / Vorsteuer n. §15(1)1 u. n. §25b(5) UStG', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 0, false);
        InsertData('66B', '66S2 / Vorsteuer n. §15(1)1 u. n. §25b(5) UStG', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false);
        InsertData('37A', '37 / Minderung Betr 19%', 1, '', 1, DemoDataSetup.DomesticCode(), MIN19Code(), '', 1, 0, true, 0, false);
        InsertData('37B', '37 / Minderung Betr 7%', 1, '', 1, DemoDataSetup.DomesticCode(), MIN7Code(), '', 1, 0, true, 0, false);
        InsertData('66', '66 / Vorsteuer n. §15(1)1 u. n. §25b(5) UStG', 2, '', 0, '', '', '66A|66B|37A|37B', 0, 0, true, 0, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('37', '37 / Minderung Betr 19%', 1, '', 1, DemoDataSetup.DomesticCode(), MIN19Code(), '', 1, 1, true, 1, false);
        InsertData('37', '37 / Minderung Betr 7%', 1, '', 1, DemoDataSetup.DomesticCode(), MIN7Code(), '', 1, 1, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('61A', '61S1 / Erwerbvorsteuer §15(1)3 UStG', 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 0, false);
        InsertData('61B', '61S2 / Erwerbvorsteuer §15(1)3 UStG', 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false);
        InsertData('61', '61 / Erwerbvorsteuer §15(1)3 UStG', 2, '', 0, '', '', '61A|61B', 0, 0, true, 0, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('62', 'Entrichtete Einfuhrumsatzsteuer §15(1)S.1 Nr.2UStG', 1, '', 1, DemoDataSetup.DomesticCode(), 'EUST', '', 1, 0, true, 0, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('83', 'Verbleibender Betrag', 2, '', 0, '', '', '81|86|35|89|93|66|61|62', 0, 0, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', 'PROBE', 0, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('10', StrSubstNo('P51 / Umsatzsteuer %1', DemoDataSetup.GoodsVATText()), 0, '1775', 0, '', '', '', 0, 0, true, 1, false);
        InsertData('11', StrSubstNo('P86 / Umsatzsteuer %1', DemoDataSetup.ServicesVATText()), 0, '1771', 0, '', '', '', 0, 0, true, 1, false);
        InsertData('12', StrSubstNo('P97 / Erwerbsteuer %1', DemoDataSetup.GoodsVATText()), 0, '1773', 0, '', '', '', 0, 0, true, 1, false);
        InsertData('13', StrSubstNo('P93 / Erwerbsteuer %1', DemoDataSetup.ServicesVATText()), 0, '1772', 0, '', '', '', 0, 0, true, 1, false);
        InsertData('14', 'P66 / Vorsteuer', 0, '1571|1575', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('15', 'P61 / Erwerbvorsteuer', 0, '1773|1784', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('16', 'Verbleibender Betrag', 2, '', 0, '', '', '10..15', 0, 0, true, 1, false);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XVAT: Label 'VAT';
        "Line No.": Integer;

    procedure InsertData("Row No.": Code[10]; Description: Text[50]; Type: Option; "Account Totaling": Text[30]; "Gen. Posting Type": Option; "VAT Bus. Posting Group": Code[20]; "VAT Prod. Posting Group": Code[20]; "Row Totaling": Text[30]; "Amount Type": Option; "Calculate with": Option; Print: Boolean; "Print with": Option; "New Page": Boolean)
    var
        "VAT Statement Line": Record "VAT Statement Line";
    begin
        "VAT Statement Line".Init();
        "VAT Statement Line".Validate("Statement Template Name", XVAT);
        "VAT Statement Line".Validate("Statement Name", 'USTVA');
        "Line No." := "Line No." + 10000;
        "VAT Statement Line".Validate("Line No.", "Line No.");
        "VAT Statement Line".Validate("Row No.", "Row No.");
        "VAT Statement Line".Validate(Description, Description);
        "VAT Statement Line".Validate(Type, Type);
        "VAT Statement Line".Validate("Account Totaling", "Account Totaling");
        "VAT Statement Line".Validate("Gen. Posting Type", "Gen. Posting Type");
        "VAT Statement Line".Validate("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        "VAT Statement Line".Validate("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        "VAT Statement Line".Validate("Row Totaling", "Row Totaling");
        "VAT Statement Line".Validate("Amount Type", "Amount Type");
        "VAT Statement Line".Validate("Calculate with", "Calculate with");
        "VAT Statement Line".Validate(Print, Print);
        "VAT Statement Line".Validate("Print with", "Print with");
        "VAT Statement Line".Validate("New Page", "New Page");
        "VAT Statement Line".Insert();
    end;

    local procedure MIN7Code(): Code[10]
    begin
        exit('MIN7');
    end;

    local procedure MIN19Code(): Code[10]
    begin
        exit('MIN19');
    end;
}

