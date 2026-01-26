codeunit 161505 "Create CH G/L Account"
{

    trigger OnRun()
    begin
        // 0 Konto, 1 Titel, 2 Summe, 3 Von Summe, 4 Bis Summe
        // Konto, Bez, Bil/Erfolg,Zeilenart,Summe,Gesch BG,Prod BG
        InsertRec('1', K1, 1, 3, '', '', '');
        InsertRec('10', K10, 1, 3, '', '', '');
        InsertRec('100', K100, 1, 3, '', '', '');
        InsertRec('1000', K1000, 1, 0, '', '', '');
        InsertRec('1010', K1010, 1, 0, '', '', '');
        InsertRec('1020', K1020, 1, 0, '', '', '');
        InsertRec('1022', K1022, 1, 0, '', '', '');
        InsertRec('1026', K1026, 1, 0, '', '', '');
        InsertRec('1028', K1028, 1, 0, '', '', '');
        InsertRec('1030', K1030, 1, 0, '', '', '');
        InsertRec('1050', K1050, 1, 0, '', '', '');
        InsertRec('1090', K1090, 1, 0, '', '', '');
        InsertRec('1099', K1099, 1, 4, '', '', '');

        InsertRec('110', K110, 1, 3, '', '', '');
        InsertRec('110.0', K110_0, 1, 1, '', '', '');
        InsertRec('1100', K1100, 1, 0, '', '', '');
        InsertRec('1101', K1101, 1, 0, '', '', '');
        InsertRec('1102', K1102, 1, 0, '', '', '');
        InsertRec('1105', K1105, 1, 0, '', '', '');
        InsertRec('1120', K1120, 1, 0, '', '', '');

        InsertRec('114.0', K114_0, 1, 1, '', '', '');
        InsertRec('1140', K1140, 1, 0, '', '', '');
        InsertRec('1160', K1160, 1, 0, '', '', '');

        InsertRec('117.0', K117_0, 1, 1, '', '', '');
        InsertRec('1170', K1170, 1, 0, '', '', '');
        InsertRec('1171', K1171, 1, 0, '', '', '');
        InsertRec('1174', K1174, 1, 0, '', xCodeCH, xCodeImport);
        InsertRec('1176', K1176, 1, 0, '', '', '');

        InsertRec('119.0', K119_0, 1, 1, '', '', '');
        InsertRec('1190', K1190, 1, 0, '', '', '');
        InsertRec('1192', K1192, 1, 0, '', '', xCodeFrei);
        InsertRec('1193', K1193, 1, 0, '', '', xCodeNormal);

        InsertRec('1199', K1199, 1, 4, '', '', '');

        InsertRec('120', K120, 1, 3, '', '', '');
        InsertRec('1200', K1200, 1, 0, '', '', '');
        InsertRec('1201', K1201, 1, 0, '', '', '');
        InsertRec('1209', K1209, 1, 0, '', '', '');
        InsertRec('1210', K1210, 1, 0, '', '', '');
        InsertRec('1211', K1211, 1, 0, '', '', '');
        InsertRec('1219', K1219, 1, 0, '', '', '');
        InsertRec('1260', K1260, 1, 0, '', '', '');
        InsertRec('1261', K1261, 1, 0, '', '', '');
        InsertRec('1269', K1269, 1, 0, '', '', '');
        InsertRec('1280', K1280, 1, 0, '', '', '');
        InsertRec('1282', K1282, 1, 0, '', '', '');
        InsertRec('1285', K1285, 1, 0, '', '', '');

        InsertRec('1299', K1299, 1, 4, '', '', '');

        InsertRec('130', K130, 1, 1, '', '', '');
        InsertRec('1300', K1300, 1, 0, '', '', '');
        InsertRec('1301', K1301, 1, 0, '', '', '');
        InsertRec('1398', K1398, 1, 0, '', '', '');
        InsertRec('1399', K1399, 1, 4, '', '', '');

        InsertRec('14', K14, 1, 3, '', '', '');
        InsertRec('140', K140, 1, 3, '', '', '');
        InsertRec('1400', K1400, 1, 0, '', '', '');
        InsertRec('1410', K1410, 1, 0, '', '', '');
        InsertRec('1420', K1420, 1, 0, '', '', '');
        InsertRec('1440', K1440, 1, 0, '', '', '');
        InsertRec('1460', K1460, 1, 0, '', '', '');
        InsertRec('1499', K1499, 1, 4, '', '', '');

        InsertRec('150', K150, 1, 3, '', '', '');
        InsertRec('1500', K1500, 1, 0, '', '', xCodeBetrieb);
        InsertRec('1509', K1509, 1, 0, '', '', '');
        InsertRec('1510', K1510, 1, 0, '', '', xCodeBetrieb);
        InsertRec('1519', K1519, 1, 0, '', '', '');
        InsertRec('1520', K1520, 1, 0, '', '', xCodeBetrieb);
        InsertRec('1521', K1521, 1, 0, '', '', xCodeBetrieb);
        InsertRec('1529', K1529, 1, 0, '', '', '');

        InsertRec('1530', K1530, 1, 0, '', '', xCodeBetrieb);
        InsertRec('1539', K1539, 1, 0, '', '', '');

        InsertRec('1540', K1540, 1, 0, '', '', xCodeBetrieb);
        InsertRec('1549', K1549, 1, 0, '', '', '');
        InsertRec('1599', K1599, 1, 4, '', '', '');
        InsertRec('160', K160, 1, 3, '', '', '');
        InsertRec('1600', K1600, 1, 0, '', '', '');
        InsertRec('1609', K1609, 1, 0, '', '', '');
        InsertRec('1699', K1699, 1, 4, '', '', '');

        InsertRec('170', K170, 1, 3, '', '', '');
        InsertRec('1700', K1700, 1, 0, '', '', xCodeFrei);
        InsertRec('1710', K1710, 1, 0, '', '', xCodeFrei);
        InsertRec('1798', K1798, 1, 4, '', '', '');

        InsertRec('1799', K1799, 1, 4, '', '', '');

        InsertRec('18', K18, 1, 3, '', '', '');
        InsertRec('1800', K1800, 1, 0, '', '', '');
        InsertRec('1850', K1850, 1, 0, '', '', '');
        InsertRec('1899', K1899, 1, 4, '', '', '');

        InsertRec('19', K19, 1, 1, '', '', '');
        InsertRec('1900', K1900, 1, 0, '', '', '');
        InsertRec('1999', K1999, 1, 4, '996..1994', '', '');

        // PASSIVEN
        InsertRec('2', K2, 1, 3, '', '', '');
        InsertRec('20', K20, 1, 3, '', '', '');
        InsertRec('200', K200, 1, 1, '', '', '');
        InsertRec('2000', K2000, 1, 0, '', '', '');
        InsertRec('2001', K2001, 1, 0, '', '', '');
        InsertRec('2002', K2002, 1, 0, '', '', '');
        InsertRec('2005', K2005, 1, 0, '', '', '');
        InsertRec('2030', K2030, 1, 0, '', '', xCodeFrei);
        InsertRec('2031', K2031, 1, 0, '', '', xCodeNormal);
        InsertRec('2100', K2100, 1, 0, '', '', '');
        InsertRec('2160', K2160, 1, 0, '', '', '');

        InsertRec('220', K220, 1, 1, '', '', '');
        InsertRec('2200', K2200, 1, 0, '', '', '');
        InsertRec('2210', K2210, 1, 0, '', '', '');
        InsertRec('2230', K2230, 1, 0, '', '', '');

        InsertRec('230', K230, 1, 1, '', '', '');
        InsertRec('2300', K2300, 1, 0, '', '', '');
        InsertRec('2301', K2301, 1, 0, '', '', '');
        InsertRec('2330', K2330, 1, 0, '', '', '');
        InsertRec('2340', K2340, 1, 0, '', '', '');
        InsertRec('2399', K2399, 1, 4, '', '', '');

        InsertRec('24', K24, 1, 3, '', '', '');
        InsertRec('240', K240, 1, 1, '', '', '');
        InsertRec('2400', K2400, 1, 0, '', '', '');
        InsertRec('2440', K2440, 1, 0, '', '', '');
        InsertRec('260', K260, 1, 1, '', '', '');
        InsertRec('2600', K2600, 1, 0, '', '', '');
        InsertRec('2630', K2630, 1, 0, '', '', '');
        InsertRec('2640', K2640, 1, 0, '', '', '');
        InsertRec('2798', K2798, 1, 4, '', '', '');
        InsertRec('2799', K2799, 1, 2, '2000..2798', '', '');  // Sum
        InsertRec('28', K28, 1, 3, '', '', '');
        InsertRec('280', K280, 1, 1, '', '', '');
        InsertRec('2800', K2800, 1, 0, '', '', '');
        InsertRec('290', K290, 1, 1, '', '', '');
        InsertRec('2900', K2900, 1, 0, '', '', '');
        InsertRec('2910', K2910, 1, 0, '', '', '');
        InsertRec('2915', K2915, 1, 0, '', '', '');
        InsertRec('2989', K2989, 1, 1, '', '', '');
        InsertRec('2990', K2990, 1, 0, '', '', '');
        InsertRec('2991', K2991, 1, 0, '', '', '');
        InsertRec('2995', K2995, 1, 2, '2900..2991', '', '');
        InsertRec('2996', K2996, 1, 4, '2796..2994', '', '');
        InsertRec('2997', K2997, 1, 4, '1995..2995', '', '');
        InsertRec('2998', K2998, 1, 2, '1000..2997', '', '');  // Sum

        // ERTRAG
        InsertRec('2999', K2999, 0, 1, '', '', '');
        InsertRec('3', K3, 0, 3, '', '', '');
        InsertRec('30', K30, 0, 1, '', '', '');
        InsertRec('3000', K3000, 0, 0, '', xCodeCH, xCodeNormal);
        InsertRec('3002', K3002, 0, 0, '', xCodeAusland, xCodeNormal);
        InsertRec('3004', K3004, 0, 0, '', xCodeAusland, xCodeNormal);
        InsertRec('3080', K3080, 0, 0, '', '', '');
        InsertRec('3081', K3081, 0, 0, '', '', '');
        InsertRec('32', K32, 0, 1, '', '', '');
        InsertRec('3200', K3200, 0, 0, '', xCodeCH, xCodeNormal);
        InsertRec('3202', K3202, 0, 0, '', xCodeAusland, xCodeNormal);
        InsertRec('3204', K3204, 0, 0, '', xCodeAusland, xCodeNormal);
        InsertRec('3280', K3280, 0, 0, '', '', '');
        InsertRec('3281', K3281, 0, 0, '', '', '');
        InsertRec('34', K34, 0, 1, '', '', '');
        InsertRec('3400', K3400, 0, 0, '', xCodeCH, xCodeNormal);
        InsertRec('3402', K3402, 0, 0, '', xCodeAusland, xCodeNormal);
        InsertRec('3404', K3404, 0, 0, '', xCodeAusland, xCodeNormal);
        InsertRec('3420', K3420, 0, 0, '', '', xCodeNormal);
        InsertRec('3421', K3421, 0, 0, '', '', xCodeNormal);  // 5.00
        InsertRec('3430', K3430, 0, 0, '', '', xCodeNormal);
        InsertRec('3480', K3480, 0, 0, '', '', '');
        InsertRec('36', K36, 0, 1, '', '', '');
        InsertRec('3600', K3600, 0, 0, '', '', '');
        InsertRec('3700', K3700, 0, 0, '', '', '');
        InsertRec('3800', K3800, 0, 0, '', '', '');
        InsertRec('39', K39, 0, 1, '', '', '');
        InsertRec('3900', K3900, 0, 0, '', xCodeCH, xCodeNormal);
        InsertRec('3901', K3901, 0, 0, '', xCodeCH, xCodeNormal);
        InsertRec('3905', K3905, 0, 0, '', '', '');
        InsertRec('3906', K3906, 0, 0, '', '', '');
        InsertRec('3907', K3907, 0, 0, '', '', '');
        InsertRec('3908', K3908, 0, 0, '', xCodeCH, xCodeNormal);
        InsertRec('3999', K3999, 0, 4, '2997..3996', '', '');

        // AUFWAND
        InsertRec('4', K4, 0, 3, '', '', '');
        InsertRec('40', K40, 0, 1, '', '', '');
        InsertRec('4000', K4000, 0, 0, '', xCodeCH, xCodeNormal);
        InsertRec('4002', K4002, 0, 0, '', xCodeAusland, xCodeNormal);
        InsertRec('4004', K4004, 0, 0, '', xCodeAusland, xCodeNormal);
        InsertRec('4050', K4050, 0, 0, '', '', '');
        InsertRec('4060', K4060, 0, 0, '', '', '');
        InsertRec('4070', K4070, 0, 0, '', '', '');
        InsertRec('42', K42, 0, 1, '', '', '');
        InsertRec('4200', K4200, 0, 0, '', xCodeCH, xCodeNormal);
        InsertRec('4202', K4202, 0, 0, '', xCodeAusland, xCodeNormal);
        InsertRec('4204', K4204, 0, 0, '', xCodeAusland, xCodeNormal);
        InsertRec('4250', K4250, 0, 0, '', '', '');
        InsertRec('4270', K4270, 0, 0, '', '', '');
        InsertRec('44', K44, 0, 1, '', '', '');
        InsertRec('4400', K4400, 0, 0, '', xCodeCH, xCodeNormal);
        InsertRec('4420', K4420, 0, 0, '', xCodeCH, xCodeNormal);
        InsertRec('4421', K4421, 0, 0, '', xCodeCH, xCodeNormal);  // 5.00
        InsertRec('45', K45, 0, 1, '', '', '');
        InsertRec('4500', K4500, 0, 0, '', '', xCodeBetrieb);
        InsertRec('4650', K4650, 0, 0, '', '', xCodeBetrieb);
        InsertRec('4700', K4700, 0, 0, '', '', xCodeBetrieb);
        InsertRec('4800', K4800, 0, 0, '', '', '');
        InsertRec('4820', K4820, 0, 0, '', '', '');
        InsertRec('4830', K4830, 0, 0, '', '', '');
        InsertRec('4880', K4880, 0, 0, '', '', '');
        InsertRec('4886', K4886, 0, 0, '', '', '');
        InsertRec('4890', K4890, 0, 0, '', '', '');
        InsertRec('4891', K4891, 0, 0, '', '', '');
        InsertRec('4892', K4892, 0, 0, '', '', '');
        InsertRec('4893', K4893, 0, 0, '', '', '');
        InsertRec('4894', K4894, 0, 0, '', '', '');
        InsertRec('49', K49, 0, 1, '', '', '');
        InsertRec('4900', K4900, 0, 0, '', '', xCodeNormal);
        InsertRec('4901', K4901, 0, 0, '', '', xCodeNormal);
        InsertRec('4906', K4906, 0, 0, '', '', '');
        InsertRec('4907', K4907, 0, 0, '', '', '');
        InsertRec('4908', K4908, 0, 0, '', '', xCodeFrei);
        InsertRec('4999', K4999, 0, 4, '', '', '');

        InsertRec('5', K5, 0, 3, '', '', '');
        InsertRec('5000', K5000, 0, 0, '', '', '');
        InsertRec('5200', K5200, 0, 0, '', '', '');
        InsertRec('5600', K5600, 0, 0, '', '', '');
        InsertRec('5700', K5700, 0, 0, '', '', '');
        InsertRec('5720', K5720, 0, 0, '', '', '');
        InsertRec('5730', K5730, 0, 0, '', '', '');
        InsertRec('5740', K5740, 0, 0, '', '', '');
        InsertRec('5790', K5790, 0, 0, '', '', '');
        InsertRec('5810', K5810, 0, 0, '', '', '');
        InsertRec('5820', K5820, 0, 0, '', '', '');
        InsertRec('5830', K5830, 0, 0, '', '', '');
        InsertRec('5999', K5999, 0, 4, '', '', '');

        InsertRec('6', K6, 0, 3, '', '', '');
        InsertRec('60', K60, 0, 3, '', '', '');
        InsertRec('6000', K6000, 0, 0, '', '', '');
        InsertRec('6010', K6010, 0, 0, '', '', '');
        InsertRec('6030', K6030, 0, 0, '', '', '');
        InsertRec('6040', K6040, 0, 0, '', '', '');
        InsertRec('6050', K6050, 0, 0, '', '', '');
        InsertRec('6099', K6099, 0, 4, '', '', '');

        InsertRec('61', K61, 0, 3, '', '', '');
        InsertRec('6100', K6100, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6110', K6110, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6120', K6120, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6130', K6130, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6160', K6160, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6199', K6199, 0, 4, '', '', '');

        InsertRec('62', K62, 0, 3, '', '', '');
        InsertRec('6200', K6200, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6210', K6210, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6220', K6220, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6230', K6230, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6280', K6280, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6290', K6290, 0, 0, '', '', xCodeNormal);

        InsertRec('6299', K6299, 0, 4, '', '', '');

        InsertRec('63', K63, 0, 3, '', '', '');
        InsertRec('6300', K6300, 0, 0, '', '', xCodeFrei);
        InsertRec('6310', K6310, 0, 0, '', '', xCodeFrei);
        InsertRec('6320', K6320, 0, 0, '', '', xCodeFrei);
        InsertRec('6360', K6360, 0, 0, '', '', xCodeFrei);
        InsertRec('6370', K6370, 0, 0, '', '', xCodeFrei);
        InsertRec('6399', K6399, 0, 4, '', '', '');

        InsertRec('64', K64, 0, 3, '', '', '');
        InsertRec('6400', K6400, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6460', K6460, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6499', K6499, 0, 4, '', '', '');

        InsertRec('65', K65, 0, 3, '', '', '');
        InsertRec('650', K650, 0, 1, '', '', xCodeBetrieb);
        InsertRec('6500', K6500, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6503', K6503, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6510', K6510, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6512', K6512, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6520', K6520, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6530', K6530, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6540', K6540, 0, 0, '', '', xCodeFrei);

        InsertRec('656', K656, 0, 1, '', '', xCodeBetrieb);
        InsertRec('6560', K6560, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6570', K6570, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6573', K6573, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6580', K6580, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6599', K6599, 0, 4, '', '', '');

        InsertRec('66', K66, 0, 3, '', '', '');
        InsertRec('6600', K6600, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6610', K6610, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6620', K6620, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6640', K6640, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6660', K6660, 0, 0, '', '', xCodeFrei);
        InsertRec('6670', K6670, 0, 0, '', '', xCodeFrei);
        InsertRec('6680', K6680, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6699', K6699, 0, 4, '', '', '');

        InsertRec('67', K67, 0, 3, '', '', '');
        InsertRec('6700', K6700, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6710', K6710, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6720', K6720, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6780', K6780, 0, 0, '', '', xCodeBetrieb);
        InsertRec('6799', K6799, 0, 4, '', '', '');

        InsertRec('68', K68, 0, 3, '', '', '');
        InsertRec('680', K680, 0, 1, '', '', '');
        InsertRec('6800', K6800, 0, 0, '', '', '');
        InsertRec('6802', K6802, 0, 0, '', '', '');
        InsertRec('6840', K6840, 0, 0, '', '', '');
        InsertRec('685', K685, 0, 1, '', '', '');
        InsertRec('6850', K6850, 0, 0, '', '', '');
        InsertRec('6860', K6860, 0, 0, '', '', '');
        InsertRec('6890', K6890, 0, 0, '', '', '');
        InsertRec('6899', K6899, 0, 4, '', '', '');

        InsertRec('69', K69, 0, 3, '', '', '');
        InsertRec('6900', K6900, 0, 0, '', '', '');
        InsertRec('6910', K6910, 0, 0, '', '', '');
        InsertRec('6920', K6920, 0, 0, '', '', '');
        InsertRec('6930', K6930, 0, 0, '', '', '');
        InsertRec('6940', K6940, 0, 0, '', '', '');
        InsertRec('6950', K6950, 0, 0, '', '', '');
        InsertRec('6998', K6998, 0, 4, '', '', '');
        InsertRec('6999', K6999, 0, 4, '', '', '');

        InsertRec('7', K7, 0, 3, '', '', '');
        InsertRec('7000', K7000, 0, 0, '', '', '');
        InsertRec('7010', K7010, 0, 0, '', '', '');
        InsertRec('7400', K7400, 0, 0, '', '', '');
        InsertRec('7410', K7410, 0, 0, '', '', '');
        InsertRec('7500', K7500, 0, 0, '', '', '');
        InsertRec('7510', K7510, 0, 0, '', '', '');
        InsertRec('7900', K7900, 0, 0, '', '', '');
        InsertRec('7910', K7910, 0, 0, '', '', '');
        InsertRec('7999', K7999, 0, 4, '', '', '');

        InsertRec('8', K8, 0, 3, '', '', '');
        InsertRec('8000', K8000, 0, 0, '', '', '');
        InsertRec('8010', K8010, 0, 0, '', '', '');
        InsertRec('8200', K8200, 0, 0, '', '', '');
        InsertRec('8210', K8210, 0, 0, '', '', '');
        InsertRec('8900', K8900, 0, 0, '', '', '');
        InsertRec('8998', K8998, 0, 4, '', '', '');
        InsertRec('8999', K8999, 0, 2, '3000..8998', '', '');  // Summe

        InsertRec('9', K9, 0, 3, '', '', '');
        InsertRec('9000', K9000, 1, 0, '', '', '');
        InsertRec('9100', K9100, 1, 0, '', '', '');

        GLAccIndent.Indent();
        AddCategoriesToGLAccounts();
    end;

    var
        GLAccIndent: Codeunit "G/L Account-Indent";
        Leerz: Boolean;
        xCodeBetrieb: Label 'OPEXP';
        xCodeFrei: Label 'NO VAT';
        xCodeNormal: Label 'NORMAL';
        xCodeImport: Label 'IMPORT';
        xCodeCH: Label 'DOMESTIC';
        xCodeAusland: Label 'EXPORT';
        xRetail: Label 'RETAIL';
        K1: Label 'ASSETS';
        K10: Label 'Current Assets';
        K100: Label 'Liquid Assets';
        K1000: Label 'Cash';
        K1010: Label 'Post Acc.';
        K1020: Label 'Bank Credit';
        K1022: Label 'Bank Credit Foreign Currency';
        K1026: Label 'Bank Credit EUR';
        K1028: Label 'Bank Credit USD';
        K1030: Label 'Bank Credit DKK';
        K1050: Label 'Fixed-term Dep. Inv.';
        K1090: Label 'Money Trans. Account';
        K1099: Label 'Total Liquid Assets';
        K110: Label 'Accts Receivable';
        K110_0: Label 'ARs from Ship. and Services';
        K1100: Label 'Customer Credit Domestic';
        K1101: Label 'Customer Credit EU';
        K1102: Label 'Customer Credit Foreign';
        K1105: Label 'Customer Credit IC';
        K1120: Label 'Accts Rec. with Shareholders';
        K114_0: Label 'Other ST Accts Receivables';
        K1140: Label 'ST Accts Receivables';
        K1160: Label 'ST Loan Shareholder';
        K117_0: Label 'Accts Receivables on Gov. Loc.';
        K1170: Label 'Purch. VAT Mat./DL';
        K1171: Label 'Purch.VAT Inv./Operating Exp.';
        K1174: Label '100% Purch. VAT on Imports';
        K1176: Label 'Credit withholding Tax';
        K119_0: Label 'Remain. ST Accts Receivables';
        K1190: Label 'WIR Credit';
        K1192: Label 'Vendor Prepayments VAT 0%';
        K1193: Label 'Vendor Prepayments VAT 8.0%';
        K1199: Label 'Tot. Accts Receivables';
        K120: Label 'Inventories, WIP';
        K1200: Label 'Inv. Commercial Goods';
        K1201: Label 'Inv. Commercial Goods(Interim)';
        K1209: Label 'WB Inv. Commercial Goods';
        K1210: Label 'Inv. Raw Materials';
        K1211: Label 'Inv. Raw Materials (Interim)';
        K1219: Label 'WB Inv. Raw Materials';
        K1260: Label 'Inv. Finished Products';
        K1261: Label 'Inv. Fin. Products (Interim)';
        K1269: Label 'WB Inv. Finish Products';
        K1280: Label 'Started Projects';
        K1282: Label 'WB Started Projects';
        K1285: Label 'Started Production Orders';
        K1299: Label 'Total Inventories, WIP';
        K130: Label 'Accrued Income';
        K1300: Label 'Prepaid Expenses';
        K1301: Label 'Earnings not yet received';
        K1398: Label 'Total Active Deferred Items';
        K1399: Label 'Total Current Assets';
        K14: Label 'Fixed Assets';
        K140: Label 'Financial Assets';
        K1400: Label 'Securities';
        K1410: Label 'FA Account';
        K1420: Label 'Investments';
        K1440: Label 'LT Accts Receivables';
        K1460: Label 'Loan Shareholder';
        K1499: Label 'Total Financial Assets';
        K150: Label 'Mobile Fixed Assets';
        K1500: Label 'Machines and Equipment';
        K1509: Label 'WB Machines and Equipment';
        K1510: Label 'Business Furniture';
        K1519: Label 'WB Business Furniture';
        K1520: Label 'Office Machines';
        K1521: Label 'IT Hardware and Software';
        K1529: Label 'WB Office Machines and IT';
        K1530: Label 'Vehicles';
        K1539: Label 'WB Vehicles';
        K1540: Label 'Vehicles, Equipment';
        K1549: Label 'WB Vehicles, Equipment';
        K1599: Label 'Total Mobile Fixed Assets';
        K160: Label 'Real Property FA';
        K1600: Label 'Real Estate';
        K1609: Label 'WB Real Estate';
        K1699: Label 'Total Real Property FA';
        K170: Label 'Intangible FA';
        K1700: Label 'Patents, Knowledge, Recipes';
        K1710: Label 'Brands,Prototypes,Models,Plans';
        K1798: Label 'Total Intangible FA';
        K1799: Label 'Total Fixed Assets';
        K18: Label 'Active Correcting Entries';
        K1800: Label 'Start-up Expenses';
        K1850: Label 'Excluded Capital Stock';
        K1899: Label 'Total Act. Correcting Entries';
        K19: Label 'Non-operational Assets';
        K1900: Label 'Non-operational Assets';
        K1999: Label 'Total Assets';
        K2: Label 'LIABILITIES';
        K20: Label 'Short-term Liabilities';
        K200: Label 'ST Liab. Ship/Serv.';
        K2000: Label 'Vendors Domestic';
        K2001: Label 'Vendors EU';
        K2002: Label 'Vendors Foreign';
        K2005: Label 'Vendors IC';
        K2030: Label 'Customer Prepayments VAT 0%';
        K2031: Label 'Customer Prepayments VAT 8.0%';
        K2100: Label 'Bank Overdraft';
        K2160: Label 'ST Loan to Shareholders';
        K220: Label 'Other Short-term Liabilities';
        K2200: Label 'VAT Owed';
        K2210: Label 'Vendor VAT';
        K2230: Label 'Dividends Due';
        K230: Label 'Liabilities Accrued Expenses';
        K2300: Label 'Unpaid Expenses';
        K2301: Label 'Earnings received in advance';
        K2330: Label 'Warranty Reserve';
        K2340: Label 'Taxation Reserve';
        K2399: Label 'Total Short-term Liabilities';
        K24: Label 'Long-term Liabilities';
        K240: Label 'Long-term Loans';
        K2400: Label 'Bank Loans';
        K2440: Label 'Mortgage Loans';
        K260: Label 'Long-term Reserves';
        K2600: Label 'LT Reserve Repairs';
        K2630: Label 'Long-term Warranty Work';
        K2640: Label 'LT Reserve Deferred Tax';
        K2798: Label 'Total Long-term Liabilities';
        K2799: Label 'Total Liabilities';
        K28: Label 'Shareholders Equity';
        K280: Label 'Capital';
        K2800: Label 'Capital Stock';
        K290: Label 'Reserves and Retained Earnings';
        K2900: Label 'Legal Reserves';
        K2910: Label 'Statutory Reserves';
        K2915: Label 'Free Reserves';
        K2989: Label 'Ret. Earnings/Loss Carried Fwd';
        K2990: Label 'Retained Earnings/Loss';
        K2991: Label 'Annual Earnings/Loss';
        K2995: Label 'Earned Capital';
        K2996: Label 'Total Shareholders Equity';
        K2997: Label 'Total Liabilities';
        K2998: Label 'Gain/Loss';
        K2999: Label 'INCOME STATEMENT';
        K3: Label 'OP. INCOME SHIP/SERV.';
        K30: Label 'Prod. Earnings';
        K3000: Label 'Prod. Earnings Domestic';
        K3002: Label 'Prod. Earnings Europe';
        K3004: Label 'Prod. Earnings Internat.';
        K3080: Label 'Inv. Change Finished Products';
        K3081: Label 'Inv. Chg Finished Prod.(Prov.)';
        K32: Label 'Trade Earning';
        K3200: Label 'Trade Domestic';
        K3202: Label 'Trade Europe';
        K3204: Label 'Trade Internat.';
        K3280: Label 'Inv. Change Comm. Goods';
        K3281: Label 'Inv. Change Trade (Prov.)';
        K34: Label 'Service Earnings';
        K3400: Label 'Service Earnings Domestic';
        K3402: Label 'Service Earnings Europe';
        K3404: Label 'Service Earnings Internat.';
        K3420: Label 'Project Earnings';
        K3421: Label 'Job Sales Applied Account';
        K3430: Label 'Consultancy Earnings';
        K3480: Label 'Inventory Change Req. Work';
        K36: Label 'Other Earnings';
        K3600: Label 'Other Earnings';
        K3700: Label 'Own Contribution, Own Use';
        K3800: Label 'Inventory Changes';
        K39: Label 'Drop in Earnings';
        K3900: Label 'Cash Discounts';
        K3901: Label 'Discounts';
        K3905: Label 'Loss from Accounts Rec.';
        K3906: Label 'Unrealized Exch. Rate Adjmts.';
        K3907: Label 'Realized Exchange Rate Adjmts.';
        K3908: Label 'Rounding Differences Sales';
        K3999: Label 'Total Op. Income Ship/Serv.';
        K4: Label 'COST GOODS, MATERIAL, DL.';
        K40: Label 'Cost of Materials';
        K4000: Label 'Cost of Material Domestic';
        K4002: Label 'Cost of Materials Europe';
        K4004: Label 'Cost of Materials Internat.';
        K4050: Label 'Variance Purch. Materials';
        K4060: Label 'Subcontracting';
        K4070: Label 'Overhead Costs Mat./Prod.';
        K42: Label 'Cost of Commercial Goods';
        K4200: Label 'Cost of Comm. Goods Domestic';
        K4202: Label 'Cost of Comm. Goods Europe';
        K4204: Label 'Cost of Comm. Goods Intl.';
        K4250: Label 'Variance Purch. Trade';
        K4270: Label 'Overhead Costs Comm. Good';
        K44: Label 'Cost of Subcontracts';
        K4400: Label 'Subcontr. of SP Operations';
        K4420: Label 'Job Costs';
        K4421: Label 'Job Costs WIP';
        K45: Label 'Other Costs';
        K4500: Label 'Energy Costs';
        K4650: Label 'Packaging Costs';
        K4700: Label 'Direct Purch. Costs';
        K4800: Label 'Inv. Change Production Mat.';
        K4820: Label 'Inv. Change Comm. Goods';
        K4830: Label 'Inv. Change Projects';
        K4880: Label 'Material Loss';
        K4886: Label 'Goods Loss';
        K4890: Label 'Material Variance Production';
        K4891: Label 'Capacity Variance Production';
        K4892: Label 'Variance Mat. Overhead Costs';
        K4893: Label 'Variance Cap. Overhead Costs';
        K4894: Label 'Variance Subcontracting';
        K49: Label 'Cost Reductions';
        K4900: Label 'Purchase Disc.';
        K4901: Label 'Cost Reduction, Discount';
        K4906: Label 'Unreal. Exchange Rate Adjmts.';
        K4907: Label 'Realized Exchange Rate Adjmts.';
        K4908: Label 'Rounding Differences Purchase';
        K4999: Label 'Total Costs Goods, Mat, Dl.';
        K5: Label 'PERSONNEL COSTS';
        K5000: Label 'Wages Production';
        K5200: Label 'Wages Sales';
        K5600: Label 'Wages Management';
        K5700: Label 'AHV, IV, EO, ALV';
        K5720: Label 'Pension Planning';
        K5730: Label 'Casualty Insurance';
        K5740: Label 'Health Insurance';
        K5790: Label 'Income tax';
        K5810: Label 'Trng and Continuing Ed.';
        K5820: Label 'Reimbursement of Expenses';
        K5830: Label 'Other Personnel Costs';
        K5999: Label 'Total Personnel Costs';
        K6: Label 'OTHER OPERATING EXPENSES';
        K60: Label 'Premises Costs';
        K6000: Label 'Rent';
        K6010: Label 'Rental Value for Used Property';
        K6030: Label 'Add. Costs';
        K6040: Label 'Cleaning';
        K6050: Label 'Maint. of Business Premises';
        K6099: Label 'Total Premises Costs';
        K61: Label 'Maint., Repairs';
        K6100: Label 'Maint. Production Plants';
        K6110: Label 'Maint. Sales Equipment';
        K6120: Label 'Maint. Storage Facilities';
        K6130: Label 'Maint. Office Equipment';
        K6160: Label 'Leasing Mobile Fixed Assets';
        K6199: Label 'Total Maint., Repairs';
        K62: Label 'Vehicle and Transport Costs';
        K6200: Label 'Vehicle Maint.';
        K6210: Label 'Op. Materials';
        K6220: Label 'Auto Insurance';
        K6230: Label 'Transport Tax, Rates';
        K6280: Label 'Transport Costs';
        K6290: Label 'Shipping Charge Customer';
        K6299: Label 'Total Vehicle and Transport';
        K63: Label 'Property Insurance, Rates';
        K6300: Label 'Property Insurance';
        K6310: Label 'Operating Liability';
        K6320: Label 'Downtime Insurance.';
        K6360: Label 'Tax, Rates';
        K6370: Label 'Permits, Patents';
        K6399: Label 'Total Insurance, Fees';
        K64: Label 'Energy, Waste Costs';
        K6400: Label 'Energy Costs';
        K6460: Label 'Waste Costs';
        K6499: Label 'Total Energy, Waste';
        K65: Label 'Management, Information Costs';
        K650: Label 'Administrative Costs';
        K6500: Label 'Office Mat., Print Supplies';
        K6503: Label 'Tech. Doc.';
        K6510: Label 'Communication, Telephone';
        K6512: Label 'Postage';
        K6520: Label 'Deductions';
        K6530: Label 'Accounting, Consultancy';
        K6540: Label 'Board of Directors,GV,Revision';
        K656: Label 'Information Costs';
        K6560: Label 'IT Leasing';
        K6570: Label 'IT Program Licenses, Maint.';
        K6573: Label 'IT Supplies';
        K6580: Label 'Consulting and Development';
        K6599: Label 'Total Administration, IT';
        K66: Label 'Advertising Costs';
        K6600: Label 'Advertisements and Media';
        K6610: Label 'Ad. Materials';
        K6620: Label 'Exhibits';
        K6640: Label 'Travel Costs, Customer Service';
        K6660: Label 'Advert. Contrib., Sponsoring';
        K6670: Label 'Public Relations / PR';
        K6680: Label 'Ad. Consultancy, Market Analy.';
        K6699: Label 'Total Advertising Costs';
        K67: Label 'Other Op. Expenses';
        K6700: Label 'Economic Information';
        K6710: Label 'Oper. Reliability, Monitoring';
        K6720: Label 'Research and Development';
        K6780: Label 'Misc. Costs';
        K6799: Label 'Total Other Operating Expenses';
        K68: Label 'Financial Income';
        K680: Label 'Financial Expenses';
        K6800: Label 'Bank Interest Rate Costs';
        K6802: Label 'Mortgage Int. Rate Costs';
        K6840: Label 'Bank and PC Costs';
        K685: Label 'Financial Profit';
        K6850: Label 'Interest Receipt Bank/Post';
        K6860: Label 'Int. Received Fin. Assets';
        K6890: Label 'Fin. Charges Rec.';
        K6899: Label 'Total Fin. Income';
        K69: Label 'Depreciation';
        K6900: Label 'Dep. Fin. Assets';
        K6910: Label 'Dep. Investment';
        K6920: Label 'Dep. Mobile Fixed Assets';
        K6930: Label 'Dep. Commercial Property';
        K6940: Label 'Dep. Intangible Fixed Assets';
        K6950: Label 'Dep. Start-up Expenses';
        K6998: Label 'Total Depreciations';
        K6999: Label 'Total Other Operating Expenses';
        K7: Label 'OTHER OPERATING INCOME';
        K7000: Label 'Subsidiary Income';
        K7010: Label 'Subsidiary Expenses';
        K7400: Label 'Income from Fin. Assets';
        K7410: Label 'Expenses from Fin. Assets';
        K7500: Label 'Property Income';
        K7510: Label 'Property Expenses';
        K7900: Label 'Gain from Sale of Fixed Assets';
        K7910: Label 'Gain/Loss from Sale of Assets';
        K7999: Label 'Total Other Operating Income';
        K8: Label 'N.R.., NON-OPERATING, TAX';
        K8000: Label 'Non-regular Income';
        K8010: Label 'Non-regular Expenses';
        K8200: Label 'Non-operating Income';
        K8210: Label 'Non-operating Expenses';
        K8900: Label 'Gain/Capital Tax';
        K8998: Label 'Total N.R. N.O., Tax';
        K8999: Label 'Gain/Loss';
        K9: Label 'CLOSING';
        K9000: Label 'Income Statement';
        K9100: Label 'Opening Balance';

    procedure InsertRec(_Nr: Text[30]; _Name: Text[30]; _BilErf: Integer; _ZeilArt: Integer; _Summe: Text[30]; _GeschBG: Code[10]; _ProdBG: Code[10])
    var
        FibukontoGLAccount: Record "G/L Account";
        FibukontoGLAccountExists: Boolean;
    begin
        FibukontoGLAccountExists := FibukontoGLAccount.Get(_Nr);
        FibukontoGLAccount.Validate("No.", _Nr);
        FibukontoGLAccount.Validate(Name, _Name);
        FibukontoGLAccount.Validate("Account Type", _ZeilArt);
        FibukontoGLAccount.Validate("Income/Balance", _BilErf);
        FibukontoGLAccount.Validate("VAT Bus. Posting Group", _GeschBG);
        FibukontoGLAccount.Validate("VAT Prod. Posting Group", _ProdBG);

        if FibukontoGLAccount."Account Type" = FibukontoGLAccount."Account Type"::Posting then
            FibukontoGLAccount.Validate("Direct Posting", true);
        FibukontoGLAccount.Validate("Income/Balance", _BilErf);

        if _Summe <> '' then
            FibukontoGLAccount.Validate(Totaling, _Summe);

        // Leerzeile nach Bis-Summe, Flag setzen
        if Leerz then begin
            FibukontoGLAccount."No. of Blank Lines" := 1;
            Leerz := false;
        end;

        if FibukontoGLAccount."Account Type" = FibukontoGLAccount."Account Type"::"End-Total" then
            Leerz := true;

        // Forderungskonti Abstimmbar
        if (FibukontoGLAccount."No." >= '1000') and (FibukontoGLAccount."No." < '1098') and
           (FibukontoGLAccount."Account Type" = FibukontoGLAccount."Account Type"::Posting)
        then
            FibukontoGLAccount."Reconciliation Account" := true;

        // Nicht Direkt auf Sammel- und MWSt Konten
        if FibukontoGLAccount."No." in ['1100', '1101', '1102'
                               , '1170', '1171', '1200', '1201', '1210', '1211', '1260', '1261', '1280', '1282', '2000', '2001', '2002']
        then
            FibukontoGLAccount."Direct Posting" := false;

        // Neue Seite letztes Bilanzkonto
        if FibukontoGLAccount."No." = '2998' then
            FibukontoGLAccount."New Page" := true;

        // Buchungsart setzen
        // Buchungsart Einkauf/Verkauf und Standard Geschäft BG = CH
        if FibukontoGLAccount."VAT Prod. Posting Group" <> '' then begin
            if (FibukontoGLAccount."No." >= '3000') and (FibukontoGLAccount."No." <= '3999') then
                FibukontoGLAccount."Gen. Posting Type" := FibukontoGLAccount."Gen. Posting Type"::Sale;
            if (FibukontoGLAccount."No." >= '4000') and (FibukontoGLAccount."No." <= '6999') then
                FibukontoGLAccount."Gen. Posting Type" := FibukontoGLAccount."Gen. Posting Type"::Purchase;
            if (FibukontoGLAccount."No." >= '1000') and (FibukontoGLAccount."No." <= '1999') then
                FibukontoGLAccount."Gen. Posting Type" := FibukontoGLAccount."Gen. Posting Type"::Purchase;

            if FibukontoGLAccount."No." = '6290' then  // Versandkostenanteil
                FibukontoGLAccount."Gen. Posting Type" := FibukontoGLAccount."Gen. Posting Type"::Sale;

            if FibukontoGLAccount."VAT Bus. Posting Group" = '' then
                FibukontoGLAccount."VAT Bus. Posting Group" := xCodeCH;

            // Gesch und Prod. BG setzen
            FibukontoGLAccount."Gen. Bus. Posting Group" := xCodeCH;
            FibukontoGLAccount."Gen. Prod. Posting Group" := xRetail;
        end;

        if FibukontoGLAccountExists then
            FibukontoGLAccount.Modify()
        else
            FibukontoGLAccount.Insert();
    end;

    procedure AddCategoriesToGLAccounts()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if GLAccountCategory.IsEmpty() then
            exit;

        GLAccountCategory.SetRange("Parent Entry No.", 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignCategoryToChartOfAccounts(GLAccountCategory);
            until GLAccountCategory.Next() = 0;

        GLAccountCategory.SetFilter("Parent Entry No.", '<>%1', 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignSubcategoryToChartOfAccounts(GLAccountCategory);
            until GLAccountCategory.Next() = 0;
    end;

    procedure AssignCategoryToChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    begin
        case GLAccountCategory."Account Category" of
            GLAccountCategory."Account Category"::Assets:
                begin
                    UpdateGLAccounts(GLAccountCategory, '1', '1');
                    UpdateGLAccounts(GLAccountCategory, '10', '19');
                    // UpdateGLAccounts(GLAccountCategory,'69','69');
                    UpdateGLAccounts(GLAccountCategory, '100', '170');
                    UpdateGLAccounts(GLAccountCategory, '1000', '1999');
                    // UpdateGLAccounts(GLAccountCategory,'6900','6998');
                end;
            GLAccountCategory."Account Category"::Liabilities:
                begin
                    UpdateGLAccounts(GLAccountCategory, '2', '2');
                    UpdateGLAccounts(GLAccountCategory, '20', '24');
                    UpdateGLAccounts(GLAccountCategory, '200', '260');
                    UpdateGLAccounts(GLAccountCategory, '2000', '2799');
                    UpdateGLAccounts(GLAccountCategory, '2978', '2998');
                end;
            GLAccountCategory."Account Category"::Equity:
                begin
                    UpdateGLAccounts(GLAccountCategory, '28', '28');
                    UpdateGLAccounts(GLAccountCategory, '280', '290');
                    UpdateGLAccounts(GLAccountCategory, '2800', '2996');
                    UpdateGLAccounts(GLAccountCategory, '9110', '9111');
                end;
            GLAccountCategory."Account Category"::Income:
                begin
                    UpdateGLAccounts(GLAccountCategory, '3', '3');
                    UpdateGLAccounts(GLAccountCategory, '8', '9');
                    UpdateGLAccounts(GLAccountCategory, '20', '24');
                    UpdateGLAccounts(GLAccountCategory, '39', '39');
                    UpdateGLAccounts(GLAccountCategory, '68', '68');
                    UpdateGLAccounts(GLAccountCategory, '680', '685');
                    UpdateGLAccounts(GLAccountCategory, '2999', '3490');
                    UpdateGLAccounts(GLAccountCategory, '3900', '3999');
                    UpdateGLAccounts(GLAccountCategory, '6799', '8999');
                    UpdateGLAccounts(GLAccountCategory, '6800', '6899');
                    UpdateGLAccounts(GLAccountCategory, '7900', '8000');
                    UpdateGLAccounts(GLAccountCategory, '8200', '8201');
                    UpdateGLAccounts(GLAccountCategory, '8900', '8999');
                end;
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                begin
                    UpdateGLAccounts(GLAccountCategory, '4', '4');
                    UpdateGLAccounts(GLAccountCategory, '40', '49');
                    UpdateGLAccounts(GLAccountCategory, '4000', '4999');
                    UpdateGLAccounts(GLAccountCategory, '7705', '7895');
                end;
            GLAccountCategory."Account Category"::Expense:
                begin
                    UpdateGLAccounts(GLAccountCategory, '5', '7');
                    UpdateGLAccounts(GLAccountCategory, '36', '36');
                    UpdateGLAccounts(GLAccountCategory, '60', '67');
                    UpdateGLAccounts(GLAccountCategory, '650', '656');
                    UpdateGLAccounts(GLAccountCategory, '5000', '6799');
                    UpdateGLAccounts(GLAccountCategory, '6999', '7510');
                    UpdateGLAccounts(GLAccountCategory, '8200', '8201');
                    UpdateGLAccounts(GLAccountCategory, '8010', '8011');
                end;
        end;
    end;

    procedure AssignSubcategoryToChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetCurrentAssets():
                begin
                    UpdateGLAccounts(GLAccountCategory, '10', '10');
                    UpdateGLAccounts(GLAccountCategory, '1399', '1399');
                end;
            GLAccountCategoryMgt.GetCash():
                begin
                    UpdateGLAccounts(GLAccountCategory, '100', '100');
                    UpdateGLAccounts(GLAccountCategory, '1000', '1099');
                end;
            GLAccountCategoryMgt.GetAR():
                begin
                    UpdateGLAccounts(GLAccountCategory, '110', '120');
                    UpdateGLAccounts(GLAccountCategory, '1100', '1199');
                end;
            GLAccountCategoryMgt.GetPrepaidExpenses():
                begin
                    UpdateGLAccounts(GLAccountCategory, '130', '130');
                    UpdateGLAccounts(GLAccountCategory, '1300', '1398');
                end;
            GLAccountCategoryMgt.GetInventory():
                begin
                    UpdateGLAccounts(GLAccountCategory, '120', '120');
                    UpdateGLAccounts(GLAccountCategory, '1200', '1299');
                end;
            GLAccountCategoryMgt.GetEquipment():
                ;
            GLAccountCategoryMgt.GetAccumDeprec():
                ;
            GLAccountCategoryMgt.GetCurrentLiabilities():
                begin
                    UpdateGLAccounts(GLAccountCategory, '20', '20');
                    UpdateGLAccounts(GLAccountCategory, '200', '230');
                    UpdateGLAccounts(GLAccountCategory, '1757', '1798');
                    UpdateGLAccounts(GLAccountCategory, '2000', '2399');
                end;
            GLAccountCategoryMgt.GetPayrollLiabilities():
                UpdateGLAccounts(GLAccountCategory, '1739', '1756');
            GLAccountCategoryMgt.GetLongTermLiabilities():
                begin
                    UpdateGLAccounts(GLAccountCategory, '24', '24');
                    UpdateGLAccounts(GLAccountCategory, '240', '260');
                    UpdateGLAccounts(GLAccountCategory, '2400', '2799');
                end;
            GLAccountCategoryMgt.GetCommonStock():
                UpdateGLAccounts(GLAccountCategory, '0790', '0844');
            GLAccountCategoryMgt.GetRetEarnings():
                UpdateGLAccounts(GLAccountCategory, '0845', '0869');
            GLAccountCategoryMgt.GetDistrToShareholders():
                UpdateGLAccounts(GLAccountCategory, '0871', '0948');
            GLAccountCategoryMgt.GetIncomeService():
                begin
                    UpdateGLAccounts(GLAccountCategory, '34', '34');
                    UpdateGLAccounts(GLAccountCategory, '3400', '3490');
                end;
            GLAccountCategoryMgt.GetIncomeProdSales():
                begin
                    UpdateGLAccounts(GLAccountCategory, '3', '3');
                    UpdateGLAccounts(GLAccountCategory, '30', '32');
                    UpdateGLAccounts(GLAccountCategory, '2999', '3281');
                end;
            GLAccountCategoryMgt.GetIncomeSalesDiscounts():
                begin
                    UpdateGLAccounts(GLAccountCategory, '39', '39');
                    UpdateGLAccounts(GLAccountCategory, '3900', '3999');
                end;
            GLAccountCategoryMgt.GetIncomeSalesReturns():
                ;
            GLAccountCategoryMgt.GetIncomeInterest():
                begin
                    UpdateGLAccounts(GLAccountCategory, '68', '68');
                    UpdateGLAccounts(GLAccountCategory, '680', '685');
                    UpdateGLAccounts(GLAccountCategory, '6800', '6899');
                end;
            GLAccountCategoryMgt.GetJobSalesContra():
                UpdateGLAccounts(GLAccountCategory, '8450', '8460');
            GLAccountCategoryMgt.GetCOGSLabor():
                UpdateGLAccounts(GLAccountCategory, '7705', '7795');
            GLAccountCategoryMgt.GetCOGSMaterials():
                begin
                    UpdateGLAccounts(GLAccountCategory, '4', '4');
                    UpdateGLAccounts(GLAccountCategory, '40', '42');
                    UpdateGLAccounts(GLAccountCategory, '49', '49');
                    UpdateGLAccounts(GLAccountCategory, '4000', '4399');
                    UpdateGLAccounts(GLAccountCategory, '4900', '4999');
                    UpdateGLAccounts(GLAccountCategory, '7805', '7895');
                end;
            GLAccountCategoryMgt.GetJobsCost():
                begin
                    UpdateGLAccounts(GLAccountCategory, '44', '45');
                    UpdateGLAccounts(GLAccountCategory, '4400', '4894');
                end;
            GLAccountCategoryMgt.GetRentExpense():
                UpdateGLAccounts(GLAccountCategory, '6000', '6010');
            GLAccountCategoryMgt.GetAdvertisingExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '66', '66');
                    UpdateGLAccounts(GLAccountCategory, '6600', '6699');
                end;
            GLAccountCategoryMgt.GetFeesExpense():
                ;
            GLAccountCategoryMgt.GetInsuranceExpense():
                ;
            GLAccountCategoryMgt.GetPayrollExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '5', '5');
                    UpdateGLAccounts(GLAccountCategory, '5000', '5999');
                end;
            GLAccountCategoryMgt.GetBenefitsExpense():
                ;
            GLAccountCategoryMgt.GetSalariesExpense():
                UpdateGLAccounts(GLAccountCategory, '4099', '4198');
            GLAccountCategoryMgt.GetRepairsExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '61', '61');
                    UpdateGLAccounts(GLAccountCategory, '6050', '6050');
                    UpdateGLAccounts(GLAccountCategory, '6100', '6200');
                end;
            GLAccountCategoryMgt.GetUtilitiesExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '6', '6');
                    UpdateGLAccounts(GLAccountCategory, '60', '60');
                    UpdateGLAccounts(GLAccountCategory, '62', '65');
                    UpdateGLAccounts(GLAccountCategory, '650', '656');
                    UpdateGLAccounts(GLAccountCategory, '6030', '6040');
                    UpdateGLAccounts(GLAccountCategory, '6099', '6099');
                    UpdateGLAccounts(GLAccountCategory, '6210', '6599');
                end;
            GLAccountCategoryMgt.GetOtherIncomeExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '7', '7');
                    UpdateGLAccounts(GLAccountCategory, '36', '36');
                    UpdateGLAccounts(GLAccountCategory, '67', '67');
                    UpdateGLAccounts(GLAccountCategory, '3600', '3800');
                    UpdateGLAccounts(GLAccountCategory, '6700', '6799');
                    UpdateGLAccounts(GLAccountCategory, '7000', '7510');
                end;
            GLAccountCategoryMgt.GetTaxExpense():
                UpdateGLAccounts(GLAccountCategory, '8900', '8956');
        end;
    end;

    local procedure UpdateGLAccounts(GLAccountCategory: Record "G/L Account Category"; FromGLAccountNo: Code[20]; ToGLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if not TryGetGLAccountNoRange(GLAccount, FromGLAccountNo, ToGLAccountNo) then
            exit;

        GLAccount.ModifyAll("Account Category", GLAccountCategory."Account Category", false);
        GLAccount.ModifyAll("Account Subcategory Entry No.", GLAccountCategory."Entry No.", false);
    end;

    [TryFunction]
    local procedure TryGetGLAccountNoRange(var GLAccount: Record "G/L Account"; FromGLAccountNo: Code[20]; ToGLAccountNo: Code[20])
    var
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        GLAccount.SetRange("No.", MakeAdjustments.Convert(FromGLAccountNo), MakeAdjustments.Convert(ToGLAccountNo));
    end;
}

