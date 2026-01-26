codeunit 160802 "GL Account Convert Scheme"
{

    trigger OnRun()
    begin
        kontokonvertering.DeleteAll();
        insertData('1000', '', 1, 1, 0, false, false, false,
                    false, 0, '', 0, '', '', '', '', '1000', '1,0E+19');
        insertData('1002', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1002', '1,002E+19');
        insertData('1003', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1003', '1,003E+19');
        insertData('1005', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1005', '1,005E+19');
        insertData('1100', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1100', '1,1E+19');
        insertData('1110', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1110', '1,11E+19');
        insertData('1120', '', 0, 1, 0, false, false, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '1120', '1,12E+19');
        insertData('1130', '', 0, 1, 0, false, false, false, false,
                    0, '', 2, XCustDom, XMisc, XCustHigh, XHigh, '1130', '1,13E+19');
        insertData('1140', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1140', '1,14E+19');
        insertData('1190', '', 4, 1, 0, false, false, false, false,
                    0, '1100..1190', 0, '', '', '', '', '1190', '1,19E+19');
        insertData('1200', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1200', '1,2E+19');
        insertData('1210', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1210', '1,21E+19');
        insertData('1220', '', 0, 1, 0, false, false, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '1220', '1,22E+19');
        insertData('1230', '', 0, 1, 0, false, false, false, false,
                    0, '', 2, XCustDom, XMisc, XCustHigh, XHigh, '1230', '1,23E+19');
        insertData('1240', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1240', '1,24E+19');
        insertData('1290', '', 4, 1, 0, false, false, false, false,
                    0, '1200..1290', 0, '', '', '', '', '1290', '1,29E+19');
        insertData('1300', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1300', '1,3E+19');
        insertData('1310', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1310', '1,31E+19');
        insertData('1320', '', 0, 1, 0, false, false, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '1320', '1,32E+19');
        insertData('1330', '', 0, 1, 0, false, false, false, false,
                    0, '', 2, XCustDom, XMisc, XCustHigh, XHigh, '1330', '1,33E+19');
        insertData('1340', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '1340', '1,34E+19');
        insertData('1390', '', 4, 1, 0, false, false, false, false,
                    0, '1300..1390', 0, '', '', '', '', '1390', '1,39E+19');
        insertData('1095', '', 4, 1, 0, false, false, false, false,
                    0, '1005..1395', 0, '', '', '', '', '1395', '1,395E+19');
        insertData('1395', '', 4, 1, 0, false, false, false, false,
                    0, '1003..1999', 0, '', '', '', '', '1999', '1,999E+19');
        insertData('1398', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2000', '2,0E+19');
        insertData('1399', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2100', '2,1E+19');
        insertData('1420', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2110', '2,11E+19');
        insertData('1425', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2111', '2,111E+19');
        insertData('1450', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2112', '4096+AF61X');
        insertData('1410', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2120', '2,12E+19');
        insertData('1415', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2121', '2,121E+19');
        insertData('1430', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2130', '2,13E+19');
        insertData('1435', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2131', '2,131E+19');
        insertData('1455', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2132', '3245X+AF2');
        insertData('1480', XWIPFinishedGoods, 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2140', '2,14E+19');
        insertData('1492', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2180', '2,18E+19');
        insertData('1495', '', 4, 1, 0, false, false, false, false,
                    0, '2100..2190', 0, '', '', '', '', '2190', '2,19E+19');
        insertData('1470', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2200', '2,2E+19');
        insertData('1472', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2210', '2,21E+19');
        insertData('1474', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2220', '2,22E+19');
        insertData('1476', '', 4, 1, 0, false, false, false, false,
                    0, '2200..2290', 0, '', '', '', '', '2290', '2,29E+19');
        insertData('1499', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2300', '2,3E+19');
        insertData('1500', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2310', '2,31E+19');
        insertData('1510', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2320', '2,32E+19');
        insertData('1520', XCustomersBusinessUnit, 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2325', '2,325E+19');
        insertData('1530', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '2330', '2,33E+19');
        insertData('1540', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '2340', '2,34E+19');
        insertData('1590', '', 4, 1, 0, false, false, false, false,
                    0, '2300..2390', 0, '', '', '', '', '2390', '2,39E+19');
        insertData('1800', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2800', '2,8E+19');
        insertData('1810', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '2810', '2,81E+19');
        insertData('1890', '', 4, 1, 0, false, false, false, false,
                    0, '2800..2890', 0, '', '', '', '', '2890', '2,89E+19');
        insertData('1899', XCashBankAccounts, 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '2900', '2,9E+19');
        insertData('1900', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '2910', '2,91E+19');
        insertData('1910', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '2920', '2,92E+19');
        insertData('1920', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '2930', '2,93E+19');
        insertData('2380', XRevolvingCredit, 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '2940', '2,94E+19');
        insertData('1960', '', 4, 1, 0, false, false, false, false,
                    0, '2900..2990', 0, '', '', '', '', '2990', '2,99E+19');
        insertData('1970', '', 4, 1, 0, false, false, false, false,
                    0, '2000..2995', 0, '', '', '', '', '2995', '2,995E+19');
        insertData('1990', '', 4, 1, 0, false, false, false, true,
                    0, '1002..2999', 0, '', '', '', '', '2999', '2,999E+19');
        insertData('1995', '', 1, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '3000', '3,0E+19');
        insertData('1999', '', 1, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '3100', '3,1E+19');
        insertData('2000', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '3110', '3,11E+19');
        insertData('2020', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '3120', '3,12E+19');
        insertData('2030', '', 2, 1, 0, false, false, false, false,
                    0, '3000..8999', 0, '', '', '', '', '3195', '3,195E+19');
        insertData('2090', '', 2, 1, 0, false, false, false, false,
                    0, '2000..2020|3000..8999', 0, '', '', '', '', '3199', '3,199E+19');
        insertData('2100', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '4000', '4,0E+19');
        insertData('2120', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '4010', '4,01E+19');
        insertData('4995', '', 2, 0, 0, false, false, false, false,
                    0, '3000..4999', 0, '', '', '', '', '4995', '4,995E+19');
        insertData('2130', '', 4, 1, 0, false, false, false, false,
                    0, '4000..4999', 0, '', '', '', '', '4999', '4,999E+19');
        insertData('2095', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5000', '5,0E+19');
        insertData('2150', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5100', '5,1E+19');
        insertData('2160', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5110', '5,11E+19');
        insertData('2170', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5120', '5,12E+19');
        insertData('2180', '', 4, 1, 0, false, false, false, false,
                    0, '5100..5290', 0, '', '', '', '', '5290', '5,29E+19');
        insertData('2299', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5300', '5,3E+19');
        insertData('3700', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5310', '5,31E+19');
        insertData('2399', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5400', '5,4E+19');
        insertData('2400', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5410', '5,41E+19');
        insertData('2410', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5420', '5,42E+19');
        insertData('2420', XVendorsBusinessUnit, 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5425', '5,425E+19');
        insertData('2498', '', 4, 1, 0, false, false, false, false,
                    0, '5400..5490', 0, '', '', '', '', '5490', '5,49E+19');
        insertData('1478', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5500', '5,5E+19');
        insertData('1482', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5510', '5,51E+19');
        insertData('1484', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5530', '5,53E+19');
        insertData('1486', '', 4, 1, 0, false, false, false, false,
                    0, '5500..5590', 0, '', '', '', '', '5590', '5,59E+19');
        insertData('2699', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5600', '5,6E+19');
        insertData('2700', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5610', '5,61E+19');
        insertData('2705', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5611', '5,611E+19');
        insertData('2710', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5620', '5,62E+19');
        insertData('2720', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5630', '5,63E+19');
        insertData('2730', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5621', '5,621E+19');
        insertData('2725', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5631', '5,631E+19');
        insertData('7000', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5710', '5,71E+19');
        insertData('1080', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5720', '5,72E+19');
        insertData('2770', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5730', '5,73E+19');
        insertData('2790', XOtherGovernExp, 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5740', '5,74E+19');
        insertData('7030', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5750', '5,75E+19');
        insertData('2750', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5760', '5,76E+19');
        insertData('2760', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5780', '5,78E+19');
        insertData('2798', '', 4, 1, 0, false, false, false, false,
                    0, '5600..5790', 0, '', '', '', '', '5790', '5,79E+19');
        insertData('2502', XPrepaidServiceContracts, 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5795', '5,795E+19');
        insertData('2510', XPrepaidHardwareContracts, 0, 1, 0, false, true, false, false,
                    0, '', 2, XCustDom, XServices, XCustHigh, XHigh, '5796', '5,796E+19');
        insertData('2520', XPrepaidSoftwareContracts, 0, 1, 0, false, true, false, false,
                    0, '', 2, XCustDom, XServices, XCustHigh, XHigh, '5797', '5,797E+19');
        insertData('2598', XTotalPrepaidServiceContract, 4, 1, 0, false, false, false, false,
                    0, '5795..5799', 0, '', '', '', '', '5799', '5,799E+19');
        insertData('2599', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5800', '5,8E+19');
        insertData('2600', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5810', '5,81E+19');
        insertData('2610', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5820', '5,82E+19');
        insertData('2620', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5830', '5,83E+19');
        insertData('2630', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5840', '5,84E+19');
        insertData('2695', '', 4, 1, 0, false, false, false, false,
                    0, '5800..5890', 0, '', '', '', '', '5890', '5,89E+19');
        insertData('2899', '', 3, 1, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '5900', '5,9E+19');
        insertData('2800', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5910', '5,91E+19');
        insertData('2920', '', 0, 1, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '5920', '5,92E+19');
        insertData('2930', '', 4, 1, 0, false, false, false, false,
                    0, '5900..5990', 0, '', '', '', '', '5990', '5,99E+19');
        insertData('2995', '', 4, 1, 0, false, false, false, false,
                    0, '5300..5995', 0, '', '', '', '', '5995', '5,995E+19');
        insertData('2997', '', 4, 1, 0, false, false, false, false,
                    0, '5000..5997', 0, '', '', '', '', '5997', '5,997E+19');
        insertData('2999', '', 2, 1, 0, false, false, false, true,
                    0, '2000..2999|3000..8999', 0, '', '', '', '', '5999', '5,999E+19');
        insertData('3000', '', 1, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6000', '6E+19');
        insertData('3001', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6100', '6,1E+19');
        insertData('3002', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6105', '6,105E+19');
        insertData('3010', '', 0, 0, 0, false, true, false, false,
                    0, '', 2, XCustDom, XRetail, XCustHigh, XHigh, '6110', '6,11E+19');
        insertData('3110', '', 0, 0, 0, false, true, false, false,
                    0, '', 2, XCustFor, XRetail, XCustNoVAT, XHigh, '6120', '6,12E+19');
        insertData('3130', '', 0, 0, 0, false, true, false, false,
                    0, '', 2, XCustFor, XRetail, XCustNoVAT, XHigh, '6130', '6,13E+19');
        insertData('3190', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '6190', '6,19E+19');
        insertData('3199', '', 4, 0, 0, false, false, false, false,
                    0, '6105..6195', 0, '', '', '', '', '6195', '6,195E+19');
        insertData('3200', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6205', '6,205E+19');
        insertData('3210', '', 0, 0, 0, false, false, false, false,
                    0, '', 2, XCustDom, XRawMat, XCustHigh, XHigh, '6210', '6,21E+19');
        insertData('3220', '', 0, 0, 0, false, false, false, false,
                    0, '', 2, XCustFor, XRawMat, XCustNoVAT, XHigh, '6220', '6,22E+19');
        insertData('3230', '', 0, 0, 0, false, false, false, false,
                    0, '', 2, XCustFor, XRawMat, XCustNoVAT, XHigh, '6230', '6,23E+19');
        insertData('3290', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6290', '6,29E+19');
        insertData('3299', '', 4, 0, 0, false, false, false, false,
                    0, '6205..6295', 0, '', '', '', '', '6295', '6,295E+19');
        insertData('3300', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6405', '6,405E+19');
        insertData('3310', '', 0, 0, 0, false, false, false, false,
                    0, '', 2, XCustDom, XServices, XCustHigh, XLow, '6410', '6,41E+19');
        insertData('3320', '', 0, 0, 0, false, false, false, false,
                    0, '', 2, XCustFor, XServices, XCustNoVAT, XLow, '6420', '6,42E+19');
        insertData('3330', '', 0, 0, 0, false, false, false, false,
                    0, '', 2, XCustFor, XServices, XCustNoVAT, XLow, '6430', '6,43E+19');
        insertData('3390', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6490', '6,49E+19');
        insertData('3399', '', 4, 0, 0, false, false, false, false,
                    0, '6405..6495', 0, '', '', '', '', '6495', '6,495E+19');
        insertData('3400', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6605', '6,605E+19');
        insertData('3420', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6610', '6,61E+19');
        insertData('3410', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6620', '6,62E+19');
        insertData('3490', '', 4, 0, 0, false, false, false, false,
                    0, '6605..6695', 0, '', '', '', '', '6695', '6,695E+19');
        insertData('3510', '', 0, 0, 0, false, true, false, false,
                    0, '', 2, XCustDom, XServices, XCustHigh, XLow, '6710', '6,71E+19');
        insertData('3520', '', 0, 0, 0, false, true, false, false,
                    0, '', 2, XCustDom, XMisc, XCustHigh, XHigh, '6810', '6,81E+19');
        insertData('3580', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6910', '6,91E+19');
        insertData('3600', XSalesofServiceContracts, 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '6950', '6,95E+19');
        insertData('3610', XServiceContractSale, 0, 0, 0, false, true, false, false,
                    0, '', 2, XCustDom, XServices, XCustHigh, XHigh, '6955', '6,955E+19');
        insertData('3690', XTotalSaleofServContracts, 4, 0, 0, false, false, false, false,
                    0, '6950..6959', 0, '', '', '', '', '6959', '6,959E+19');
        insertData('3999', '', 4, 0, 0, false, false, false, false,
                    0, '6100..6995', 0, '', '', '', '', '6995', '6,995E+19');
        insertData('4000', '', 3, 0, 0, false, false, false, false,
                    1, '', 0, '', '', '', '', '7100', '7,1E+19');
        insertData('4001', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7105', '7,105E+19');
        insertData('4010', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XRetail, XVendHigh, XHigh, '7110', '7,11E+19');
        insertData('4020', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendFor, XRetail, XVendNoVAT, XHigh, '7120', '7,12E+19');
        insertData('4030', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendFor, XRetail, XVendNoVAT, XHigh, '7130', '7,13E+19');
        insertData('4040', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '7140', '7,14E+19');
        insertData('4050', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '7150', '7,15E+19');
        insertData('4060', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7170', '7,17E+19');
        insertData('4065', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7180', '7,18E+19');
        insertData('4070', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7190', '7,19E+19');
        insertData('4075', XDirectCostAppliedRetail, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7191', '7,191E+19');
        insertData('4080', XOverheadAppliedRetail, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7192', '7,192E+19');
        insertData('4085', XPurchaseVarianceRetail, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7193', '7,193E+19');
        insertData('4090', '', 4, 0, 0, false, false, false, false,
                    0, '7105..7195', 0, '', '', '', '', '7195', '7,195E+19');
        insertData('4100', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7205', '7,205E+19');
        insertData('4110', '', 0, 0, 0, false, false, false, false,
                    0, '', 1, XVendDom, XRawMat, XVendHigh, XHigh, '7210', '7,21E+19');
        insertData('4120', '', 0, 0, 0, false, false, false, false,
                    0, '', 1, XVendFor, XRawMat, XVendNoVAT, XHigh, '7220', '7,22E+19');
        insertData('4130', '', 0, 0, 0, false, false, false, false,
                    0, '', 1, XVendFor, XRawMat, XVendNoVAT, XHigh, '7230', '7,23E+19');
        insertData('4140', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7240', '7,24E+19');
        insertData('4150', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '7250', '7,25E+19');
        insertData('4160', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7270', '7,27E+19');
        insertData('4165', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7280', '7,28E+19');
        insertData('4170', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7290', '7,29E+19');
        insertData('4175', XDirectCostAppliedRawmat, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7291', '7,291E+19');
        insertData('4180', XOverheadAppliedRawmat, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7292', '7,292E+19');
        insertData('4185', XPurchaseVarianceRawmat, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7293', '7,293E+19');
        insertData('4190', '', 4, 0, 0, false, false, false, false,
                    0, '7205..7295', 0, '', '', '', '', '7295', '7,295E+19');
        insertData('4200', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7405', '7,405E+19');
        insertData('4210', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7480', '7,48E+19');
        insertData('4220', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '7490', '7,49E+19');
        insertData('4290', '', 4, 0, 0, false, false, false, false,
                    0, '7405..7495', 0, '', '', '', '', '7495', '7,495E+19');
        insertData('4300', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7620', '7,62E+19');
        insertData('4310', XCostofCapacities, 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7705', '7,705E+19');
        insertData('4320', XCostofCapacities, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7710', '7,71E+19');
        insertData('4330', XDirectCostAppliedCa, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7791', '7,791E+19');
        insertData('4340', XOverheadAppliedCap, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7792', '7,792E+19');
        insertData('4350', XPurchaseVarianceCap, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7793', '7,793E+19');
        insertData('4390', XTotalCostofCapacities, 4, 0, 0, false, false, false, false,
                    0, '7705..7795', 0, '', '', '', '', '7795', '7,795E+19');
        insertData('4400', XVariance, 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7805', '7,805E+19');
        insertData('4410', XMaterialVariance, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7890', '7,89E+19');
        insertData('4420', XCapacityVariance, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7891', '7,891E+19');
        insertData('4430', XSubcontractedVariance, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7892', '7,892E+19');
        insertData('4440', XCapOverheadVariance, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7893', '7,893E+19');
        insertData('4450', XMfgOverheadVariance, 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '7894', '7,894E+19');
        insertData('4490', XTotalVariance, 4, 0, 0, false, false, false, false,
                    0, '7805..7895', 0, '', '', '', '', '7895', '7,895E+19');
        insertData('4990', '', 4, 0, 0, false, false, false, false,
                    0, '7100..7995', 0, '', '', '', '', '7995', '7,995E+19');
        insertData('5998', XOtherOperatingExpenses, 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '8000', '8E+19');
        insertData('6099', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '8100', '8,1E+19');
        insertData('6360', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8110', '8,11E+19');
        insertData('6340', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8120', '8,12E+19');
        insertData('6350', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8130', '8,13E+19');
        insertData('6390', '', 4, 0, 0, false, false, false, false,
                    0, '8100..8190', 0, '', '', '', '', '8190', '8,19E+19');
        insertData('6899', XPhoneandFax, 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '8200', '8,2E+19');
        insertData('6950', XLineRentalADSL, 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8210', '8,21E+19');
        insertData('6900', XOfficeSupplies, 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8230', '8,23E+19');
        insertData('6940', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XNoVAT, XVendHigh, XHigh, '8240', '8,24E+19');
        insertData('6990', '', 4, 0, 0, false, false, false, false,
                    0, '8200..8290', 0, '', '', '', '', '8290', '8,29E+19');
        insertData('6400', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '8300', '8,3E+19');
        insertData('6410', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8310', '8,31E+19');
        insertData('6420', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XServices, XVendHigh, XLow, '8320', '8,32E+19');
        insertData('6430', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8330', '8,33E+19');
        insertData('6490', '', 4, 0, 0, false, false, false, false,
                    0, '8300..8390', 0, '', '', '', '', '8390', '8,39E+19');
        insertData('7299', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '8400', '8,4E+19');
        insertData('7300', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8410', '8,41E+19');
        insertData('7310', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XWithout, '8420', '8,42E+19');
        insertData('7320', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XNoVAT, XVendHigh, XWithout, '8430', '8,43E+19');
        insertData('7330', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8450', '8,45E+19');
        insertData('7390', '', 4, 0, 0, false, false, false, false,
                    0, '8400..8490', 0, '', '', '', '', '8490', '8,49E+19');
        insertData('6999', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '8500', '8,5E+19');
        insertData('7020', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8510', '8,51E+19');
        insertData('7040', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XNoVAT, XVendHigh, XWithout, '8520', '8,52E+19');
        insertData('7050', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8530', '8,53E+19');
        insertData('7200', '', 4, 0, 0, false, false, false, false,
                    0, '8500..8590', 0, '', '', '', '', '8590', '8,59E+19');
        insertData('6699', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '8600', '8,6E+19');
        insertData('6780', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '8610', '8,61E+19');
        insertData('6720', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '8620', '8,62E+19');
        insertData('6700', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8630', '8,63E+19');
        insertData('6710', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8640', '8,64E+19');
        insertData('6790', '', 4, 0, 0, false, false, false, false,
                    0, '8600..8690', 0, '', '', '', '', '8690', '8,69E+19');
        insertData('7898', '', 4, 0, 0, false, false, false, false,
                    0, '8000..8695', 0, '', '', '', '', '8695', '8,695E+19');
        insertData('5000', XPayroll, 3, 0, 0, false, false, false, false,
                    1, '', 0, '', '', '', '', '8700', '8,7E+19');
        insertData('5010', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '8710', '8,71E+19');
        insertData('5020', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '8720', '8,72E+19');
        insertData('5030', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '8730', '8,73E+19');
        insertData('5040', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '8740', '8,74E+19');
        insertData('5050', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '8750', '8,75E+19');
        insertData('5090', '', 4, 0, 0, false, false, false, false,
                    0, '8700..8790', 0, '', '', '', '', '8790', '8,79E+19');
        insertData('5999', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '8800', '8,8E+19');
        insertData('6000', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '8810', '8,81E+19');
        insertData('6010', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '8820', '8,82E+19');
        insertData('6020', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '8830', '8,83E+19');
        insertData('7830', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '8840', '8,84E+19');
        insertData('6090', '', 4, 0, 0, false, false, false, false,
                    0, '8800..8890', 0, '', '', '', '', '8890', '8,89E+19');
        insertData('7100', '', 0, 0, 0, false, true, false, false,
                    0, '', 1, XVendDom, XMisc, XVendHigh, XHigh, '8910', '8,91E+19');
        insertData('7990', XResultbeforeFinancial, 2, 0, 0, false, false, false, false,
                    0, '3000..7990', 0, '', '', '', '', '8995', '8,995E+19');
        insertData('7999', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9100', '9,1E+19');
        insertData('8000', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '9110', '9,11E+19');
        insertData('8020', '', 0, 0, 0, false, true, false, false,
                    0, '', 2, XCustDom, XNoVAT, XCustHigh, XWithout, '9120', '9,12E+19');
        insertData('8030', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9130', '9,13E+19');
        insertData('6800', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9135', '9,135E+19');
        insertData('8040', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, XCustDom, XNoVAT, XCustHigh, XWithout, '9140', '9,14E+19');
        insertData('8090', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '9150', '9,15E+19');
        insertData('8080', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9160', '9,16E+19');
        insertData('7150', XSubsitence, 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '9170', '9,17E+19');
        insertData('8099', '', 4, 0, 0, false, false, false, false,
                    0, '9100..9190', 0, '', '', '', '', '9190', '9,19E+19');
        insertData('8100', '', 3, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9200', '9,2E+19');
        insertData('8110', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '9210', '8110x');
        insertData('8120', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '9220', '9,22E+19');
        insertData('8130', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '9230', '9,23E+19');
        insertData('8140', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '9240', '9,24E+19');
        insertData('8150', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9250', '9,25E+19');
        insertData('7870', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9255', '9,255E+19');
        insertData('8145', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9260', '9,26E+19');
        insertData('6550', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9270', '9,27E+19');
        insertData('8199', '', 4, 0, 0, false, false, false, false,
                    0, '9200..9290', 0, '', '', '', '', '9290', '9,29E+19');
        insertData('8055', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9310', '9,31E+19');
        insertData('8155', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9320', '9,32E+19');
        insertData('8060', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9330', '9,33E+19');
        insertData('8160', '', 0, 0, 0, false, false, false, false,
                    0, '', 0, '', '', '', '', '9340', '9,34E+19');
        insertData('8299', '', 2, 0, 0, false, false, false, false,
                    0, '3000..8299', 0, '', '', '', '', '9395', '9,395E+19');
        insertData('8400', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '9410', '9,41E+19');
        insertData('8500', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '9420', '9,42E+19');
        insertData('8590', '', 2, 0, 0, false, false, false, false,
                    0, '3000..8599', 0, '', '', '', '', '9495', '9,495E+19');
        insertData('8600', '', 0, 0, 0, false, true, false, false,
                    0, '', 0, '', '', '', '', '9510', '9,51E+19');
        insertData('8999', '', 2, 0, 0, false, false, false, false,
                    0, '3000..8999', 0, '', '', '', '', '9999', '9,999E+19');

        // Prepayment accounts
        insertData('2450', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', XVendHigh, XHigh, '2400', '2,40E+19');
        insertData('1550', '', 0, 1, 0, false, false, false, false,
                    0, '', 0, '', '', XCustHigh, XHigh, '5350', '5,35E+19');
    end;

    var
        kontokonvertering: Record "GL Accounts Conversion";
        XWIPFinishedGoods: Label 'WIP Account, Finished Goods';
        XCustomersBusinessUnit: Label 'Customers, Business Unit';
        XRevolvingCredit: Label 'Revolving Credit';
        XVendorsBusinessUnit: Label 'Vendors, Business Unit';
        XPrepaidServiceContracts: Label 'Prepaid Service Contracts';
        XPrepaidHardwareContracts: Label 'Prepaid Hardware Contracts';
        XPrepaidSoftwareContracts: Label 'Prepaid Software Contracts';
        XTotalPrepaidServiceContract: Label 'Total Prepaid Service Contract';
        XDirectCostAppliedRawmat: Label 'Direct Cost Applied, Rawmat.';
        XOverheadAppliedRawmat: Label 'Overhead Applied, Rawmat.';
        XPurchaseVarianceRawmat: Label 'Purchase Variance, Rawmat.';
        XCostofCapacities: Label 'Cost of Capacities';
        XDirectCostAppliedCa: Label 'Direct Cost Applied, Cap.';
        XOverheadAppliedCap: Label 'Overhead Applied, Cap.';
        XPurchaseVarianceCap: Label 'Purchase Variance, Cap.';
        XTotalCostofCapacities: Label 'Total Cost of Capacities';
        XVariance: Label 'Variance';
        XMaterialVariance: Label 'Material Variance';
        XCapacityVariance: Label 'Capacity Variance';
        XSubcontractedVariance: Label 'Subcontracted Variance';
        XCapOverheadVariance: Label 'Cap. Overhead Variance';
        XMfgOverheadVariance: Label 'Mfg. Overhead Variance';
        XTotalVariance: Label 'Total Variance';
        XOtherOperatingExpenses: Label 'Other Operating Expenses';
        XPhoneandFax: Label 'Phone and Fax';
        XLineRentalADSL: Label 'Line Rental, ADSL';
        XOfficeSupplies: Label 'Office Supplies';
        XResultbeforeFinancial: Label 'Result before Financial';
        XSubsitence: Label 'Subsitence';
        XSalesofServiceContracts: Label 'Sales of Service Contracts';
        XServiceContractSale: Label 'Service Contract Sale';
        XTotalSaleofServContracts: Label 'Total Sale of Serv. Contracts';
        XDirectCostAppliedRetail: Label 'Direct Cost Applied, Retail';
        XOverheadAppliedRetail: Label 'Overhead Applied, Retail';
        XPurchaseVarianceRetail: Label 'Purchase Variance, Retail';
        XPayroll: Label 'Payroll';
        XCashBankAccounts: Label 'Cash, Bank Accounts etc.';
        XOtherGovernExp: Label 'Other Governmental Expenses';
        XVendDom: Label 'VENDDOM';
        XMisc: Label 'MISC';
        XVendHigh: Label 'VENDHIGH';
        XHigh: Label 'HIGH';
        XCustDom: Label 'CUSTDOM';
        XCustHigh: Label 'CUSTHIGH';
        XServices: Label 'SERVICES';
        XRetail: Label 'RETAIL';
        XVendFor: Label 'VENDFOR';
        XNoVAT: Label 'NO VAT';
        XRawMat: Label 'RAW MAT';
        XVendNoVAT: Label 'VENDNOVAT';
        XWithout: Label 'WITHOUT';
        XCustFor: Label 'CUSTFOR';
        XCustNoVAT: Label 'CUSTNOVAT';
        XLow: Label 'LOW';

    procedure insertData("Code": Code[20]; navn: Text[30]; acctype: Option Posting,Heading,Total,"Begin-Total","End-Total"; incbal: Option; debcred: Option; blocked: Boolean; dirpost: Boolean; recacc: Boolean; newpage: Boolean; noofblanklines: Integer; total: Text[250]; genposttype: Integer; genbuspostgr: Code[10]; genprodpostgr: Code[10]; vatbuspostgr: Code[10]; vatprodpostgr: Code[10]; opprinkonto: Text[20]; midlkonto: Text[20])
    begin
        kontokonvertering.Reset();
        kontokonvertering.Init();
        kontokonvertering."No." := Code;
        kontokonvertering.Validate(Name, navn);
        kontokonvertering.Validate("Search Name", UpperCase(navn));
        kontokonvertering."Account Type" := acctype;
        kontokonvertering."Income/Balance" := incbal;
        kontokonvertering."Debit/Credit" := debcred;
        kontokonvertering.Blocked := kontokonvertering.Blocked;
        kontokonvertering."Direct Posting" := dirpost;
        kontokonvertering."Reconciliation Account" := recacc;
        kontokonvertering."New Page" := newpage;
        kontokonvertering."No. of Blank Lines" := noofblanklines;
        kontokonvertering.Totaling := total;
        kontokonvertering."Gen. Posting Type" := genposttype;
        kontokonvertering."Gen. Bus. Posting Group" := genbuspostgr;
        kontokonvertering."Gen. Prod. Posting Group" := genprodpostgr;
        kontokonvertering."VAT Bus. Posting Group" := vatbuspostgr;
        kontokonvertering."VAT Prod. Posting Group" := vatprodpostgr;
        kontokonvertering."Original Account No." := opprinkonto;
        kontokonvertering."Temp. Account No." := midlkonto;
        kontokonvertering.Insert();
    end;
}

