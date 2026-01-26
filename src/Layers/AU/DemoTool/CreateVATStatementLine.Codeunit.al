codeunit 101256 "Create VAT Statement Line"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
                exit;
            InsertData(
              '1010', StrSubstNo(XSalesVATPERCENToutgoing, DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 1, false);
            InsertData(
              '1020', StrSubstNo(XSalesVATPERCENToutgoing, DemoDataSetup.ServicesVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 1, false);
            InsertData(
              '1050', XVAT25PERCENTonMISCPurchetc, 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 1, 1, false, 1, false);
            InsertData(
              '1060', XVAT10PERCENTonMISCPurchetc, 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 1, 1, false, 1, false);
            InsertData('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('1099', XTotal, 2, '', 0, '', '', '1010..1090', 0, 0, true, 1, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData(
              '1110', XInputTaxCredit25PERCENTDomes, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false);
            InsertData(
              '1120', XInputTaxCredit10PERCENTDomes, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false);
            InsertData(
              '1150', XInputTaxCredit25PERCENTMISC, 1, '', 1, DemoDataSetup.MiscCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false);
            InsertData(
              '1160', XInputTaxCredit10PERCENTMISC, 1, '', 1, DemoDataSetup.MiscCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false);
            InsertData('1179', XInputTaxCreditingoing, 2, '', 0, '', '', '1110..1170', 0, 0, true, 1, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('1180', XFuelTax, 0, CA.Convert('995710'), 0, '', '', '', 0, 0, true, 1, false);
            InsertData('1181', XElectricityTax, 0, CA.Convert('995720'), 0, '', '', '', 0, 0, true, 1, false);
            InsertData('1182', XNaturalGasTax, 0, CA.Convert('995730'), 0, '', '', '', 0, 0, true, 1, false);
            InsertData('1183', XCoalTax, 0, CA.Convert('995740'), 0, '', '', '', 0, 0, true, 1, false);
            InsertData('1184', XCO2Tax, 0, CA.Convert('995750'), 0, '', '', '', 0, 0, true, 1, false);
            InsertData('1185', XWaterTax, 0, CA.Convert('995760'), 0, '', '', '', 0, 0, true, 1, false);
            InsertData('1189', XTotalTaxes, 2, '', 0, '', '', '1180..1188', 0, 0, true, 1, false);
            InsertData('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('1199', XTotalDeductions, 2, '', 0, '', '', '1159|1189', 0, 0, true, 1, false);
            InsertData('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('', XVATPayable, 2, '', 0, '', '', '1099|1199', 0, 0, true, 1, false);
            InsertData('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData(
              '1210', XValueofMISCPurchases25PERCENT, 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
            InsertData(
              '1220', XValueofMISCPurchases10PERCENT, 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData(
              '1240', XValueofMISCSales, 1, '', 2, DemoDataSetup.MiscCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false);
            InsertData(
              '1250', XValueofMISCSales, 1, '', 2, DemoDataSetup.MiscCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('1310', XNonVATliablesalesOverseas, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
            InsertData('1320', XNonVATliablesalesOverseas, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false);
            if DemoDataSetup."Reduced VAT Rate" > 0 then
                InsertData('1330', XNonVATliablesalesOverseas, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 0, false);
            InsertData('', XNonVATliablesalesOverseas, 2, '', 0, '', '', '1310..1330', 0, 0, true, 1, false);
            InsertData('1340', XNonVATliablesalesDomestic, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false);
            InsertData('', XNonVATliablesalesDomestic, 2, '', 0, '', '', '1340..1348', 0, 0, true, 1, false);

            InsertBASData('10', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('10', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('10', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('10', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('10', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('10', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('10', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('10', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('10', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('10', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, true, '');
            // 1000
            InsertBASData(
              '1000', 'GST Sales Domestic Row Totaling', 2, '', 0, '', '', '10', 0, 0, true, 0, false, false, '1A');

            InsertBASData('20', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('20', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('20', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('20', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('20', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('20', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('20', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('20', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('20', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('20', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, true, '');
            // 2000
            InsertBASData(
              '2000', 'GST Purchase Domestic Row Totaling', 2, '', 0, '', '', '20', 0, 0, true, 0, false, false, '1B');
            // 2100
            InsertBASData(
              '2100', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, false, '1H');

            InsertBASData('30', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('30', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.InputTaxCode(), '', 2, 0, false, 0, false, false, '');
            // 3000
            InsertBASData(
              '3000', 'GST Sales Domestic/Export Row Totaling', 2, '', 0, '', '', '30', 0, 0, true, 0, false, false, 'G1');

            InsertBASData('40', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('40', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('40', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('40', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('40', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('40', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('40', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('40', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.InputTaxCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('40', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('40', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 2, 0, false, 0, false, false, '');
            // 4000
            InsertBASData(
              '4000', 'GST Sales Domestic/Export Row Totaling', 2, '', 0, '', '', '40', 0, 0, true, 0, false, false, 'G2');

            InsertBASData('50', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('50', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, false, '');
            // 5000
            InsertBASData(
              '5000', 'GST Sales DOMESTIC NOVAT Row Totaling', 2, '', 0, '', '', '50', 0, 0, true, 0, false, false, 'G3');

            InsertBASData('60', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('60', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 2, 0, false, 0, false, false, '');
            // 6000
            InsertBASData(
              '6000', 'GST Sales DOMESTIC INPUTTAX Row Totaling', 2, '', 0, '', '', '60', 0, 0, true, 0, false, false, 'G4');

            InsertBASData('70', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('70', '', 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.InputTaxCode(), '', 2, 0, false, 0, false, true, '');
            // 7000
            InsertBASData(
              '7000', 'GST Sales BAS Adj. Row Totaling', 2, '', 0, '', '', '70', 0, 0, true, 0, false, false, 'G7');

            InsertBASData('80', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('80', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('80', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('80', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 2, 0, false, 0, false, false, '');
            // 8000
            InsertBASData(
              '8000', 'GST Purch Row Totaling', 2, '', 0, '', '', '80', 0, 0, true, 0, false, false, 'G10');

            InsertBASData('90', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('90', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.InputTaxCode(), '', 2, 0, false, 0, false, false, '');
            // 9000
            InsertBASData(
              '9000', 'GST Purchase Row Totaling', 2, '', 0, '', '', '90', 0, 0, true, 0, false, false, 'G11');

            InsertBASData('100', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('100', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 2, 0, false, 0, false, false, '');
            // 10000
            InsertBASData(
              '10000', 'GST Purchase Row Totaling', 2, '', 0, '', '', '100', 0, 0, true, 0, false, false, 'G13');

            InsertBASData('110', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('110', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('110', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('110', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('110', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('110', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('110', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('110', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, false, '');
            InsertBASData('110', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, false, '');
            InsertBASData('110', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, false, '');
            // 11000
            InsertBASData(
              '11000', 'GST Purchase Row Totaling', 2, '', 0, '', '', '110', 0, 0, true, 0, false, false, 'G14');

            InsertBASData('120', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.AssetCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.AssetCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.InputTaxCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.InputTaxCode(), '', 1, 0, false, 0, false, true, '');
            InsertBASData('120', '', 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.InputTaxCode(), '', 2, 0, false, 0, false, true, '');
            // 12000
            InsertBASData('12000', '', 3, '', 0, '', '', '120', 0, 0, true, 0, false, false, 'G18');
            // 12100
            InsertBASData('12100', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, false, 'G22');
            // 12200
            InsertBASData('12200', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, false, 'G24');
            // 12300
            InsertBASData('12300', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, false, 'T3');
            // 12300
            InsertBASData('12400', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, false, 'T4');
            // 12300
            InsertBASData('12500', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, false, 'T8');
            // 12300
            InsertBASData('12600', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, false, 'T9');
            // 12300
            InsertBASData('12700', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, false, 'F2');
            // 13000
            InsertBASData('13000', 'GST Purchase Row Totaling', 0, '8710..8740', 0, '', '', '', 1, 0, true, 0, false, false, 'W1');
            // 14000
            InsertBASData('14000', 'GST Purchase Row Totaling', 0, '5810', 0, '', '', '', 1, 0, true, 0, false, false, 'W2');
            // 15000
            InsertBASData('15000', 'GST Purchase Row Totaling', 0, '5670', 0, '', '', '', 1, 0, true, 0, false, false, 'W4');
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        NextLineNo: Integer;
        CA: Codeunit "Make Adjustments";
        XSalesVATPERCENToutgoing: Label 'Sales VAT %1 (outgoing)';
        XTotal: Label 'Total';
        XFuelTax: Label 'Fuel Tax';
        XElectricityTax: Label 'Electricity Tax';
        XNaturalGasTax: Label 'Natural Gas Tax';
        XCoalTax: Label 'Coal Tax';
        XCO2Tax: Label 'CO2 Tax';
        XWaterTax: Label 'Water Tax';
        XTotalTaxes: Label 'Total Taxes';
        XTotalDeductions: Label 'Total Deductions';
        XVATPayable: Label 'VAT Payable';
        XNonVATliablesalesOverseas: Label 'Non-VAT liable sales, Overseas';
        XNonVATliablesalesDomestic: Label 'Non-VAT liable sales, Domestic';
        XVAT: Label 'VAT';
        XDEFAULT: Label 'DEFAULT';
        XVAT25PERCENTonMISCPurchetc: Label 'VAT 25 % on MISC Purchases etc.';
        XVAT10PERCENTonMISCPurchetc: Label 'VAT 10 % on MISC Purchases etc.';
        XInputTaxCredit25PERCENTDomes: Label 'Input Tax Credit 25 % Domestic';
        XInputTaxCredit10PERCENTDomes: Label 'Input Tax Credit 10 % Domestic';
        XInputTaxCredit25PERCENTMISC: Label 'Input Tax Credit 25 % MISC';
        XInputTaxCredit10PERCENTMISC: Label 'Input Tax Credit 10 % MISC';
        XInputTaxCreditingoing: Label 'Input Tax Credit (ingoing)';
        XValueofMISCPurchases25PERCENT: Label 'Value of MISC Purchases 25 %';
        XValueofMISCPurchases10PERCENT: Label 'Value of MISC Purchases 10 %';
        XValueofMISCSales: Label 'Value of MISC Sales';
        XBAS: Label 'BAS', Locked = true;

    procedure InsertData(RowNo: Code[10]; Description: Text[50]; Type: Option; AccountTotaling: Text[30]; GenPostingType: Option; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; RowTotaling: Text[30]; AmountType: Option; CalculateWith: Option; Print: Boolean; PrintWith: Option; NewPage: Boolean)
    begin
        InsertVATStatementLine(
          XVAT, RowNo, Description, Type, AccountTotaling, GenPostingType, VATBusPostingGroup, VATProdPostingGroup,
          RowTotaling, AmountType, CalculateWith, Print, PrintWith, NewPage, false, '');
    end;

    procedure InsertBASData(RowNo: Code[10]; Description: Text[50]; Type: Option; AccountTotaling: Text[30]; GenPostingType: Option; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; RowTotaling: Text[30]; AmountType: Option; CalculateWith: Option; Print: Boolean; PrintWith: Option; NewPage: Boolean; BASAdjustment: Boolean; BoxNo: Text[20])
    begin
        InsertVATStatementLine(
          XBAS, RowNo, Description, Type, AccountTotaling, GenPostingType, VATBusPostingGroup, VATProdPostingGroup,
          RowTotaling, AmountType, CalculateWith, Print, PrintWith, NewPage, BASAdjustment, BoxNo);
    end;

    procedure InsertVATStatementLine(StatementName: Code[10]; RowNo: Code[10]; Description: Text[50]; Type: Option; AccountTotaling: Text[30]; GenPostingType: Option; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; RowTotaling: Text[30]; AmountType: Option; CalculateWith: Option; Print: Boolean; PrintWith: Option; NewPage: Boolean; BASAdjustment: Boolean; BoxNo: Text[20])
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.Init();
        VATStatementLine.Validate("Statement Template Name", StatementName);
        VATStatementLine.Validate("Statement Name", XDEFAULT);
        NextLineNo := NextLineNo + 10000;
        VATStatementLine.Validate("Line No.", NextLineNo);
        VATStatementLine.Validate("Row No.", RowNo);
        VATStatementLine.Validate(Description, Description);
        VATStatementLine.Validate(Type, Type);
        VATStatementLine.Validate("Account Totaling", AccountTotaling);
        VATStatementLine.Validate("Gen. Posting Type", GenPostingType);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        VATStatementLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        VATStatementLine.Validate("Row Totaling", RowTotaling);
        VATStatementLine.Validate("Amount Type", AmountType);
        VATStatementLine.Validate("Calculate with", CalculateWith);
        VATStatementLine.Validate(Print, Print);
        VATStatementLine.Validate("Print with", PrintWith);
        VATStatementLine.Validate("New Page", NewPage);
        VATStatementLine.Validate("BAS Adjustment", BASAdjustment);
        VATStatementLine.Validate("Box No.", BoxNo);
        VATStatementLine.Insert();
    end;
}

