codeunit 101803 "Create FA Posting Group"
{

    trigger OnRun()
    begin
        InsertData('01-101_20', '01-1010', '02-1010', '01-1010', '02-1010', '91-1302', '91-2302', '20-1400', '01-9000',
          StrSubstNo(XBuildingDepreciation, '20'));
        InsertData('01-101_23', '01-1010', '02-1010', '01-1010', '02-1010', '91-1302', '91-2302', '23-1000', '01-9000',
          StrSubstNo(XAuxProduction, '23'));
        InsertData('01-101_25', '01-1010', '02-1010', '01-1010', '02-1010', '91-1302', '91-2302', '25-1000', '01-9000',
          StrSubstNo(XManufOverheadCosts, '25'));
        InsertData('01-101_26', '01-1010', '02-1010', '01-1010', '02-1010', '91-1302', '91-2302', '26-5000', '01-9000',
          StrSubstNo(XBuildingDepreciation, '26'));
        InsertData('01-101_29', '01-1010', '02-1010', '01-1010', '02-1010', '91-1302', '91-2302', '29-1000', '01-9000',
          StrSubstNo(XServManufAndMaint, '29'));
        InsertData('01-101_44', '01-1010', '02-1010', '01-1010', '02-1010', '91-1302', '91-2302', '44-2400', '01-9000',
          StrSubstNo(XBuildingDepreciation, '44'));
        InsertData('01-102_20', '01-1020', '02-1020', '01-1020', '02-1020', '91-1302', '91-2302', '20-1400', '01-9000',
          StrSubstNo(XConstAndTransMechanism, '20'));
        InsertData('01-102_23', '01-1020', '02-1020', '01-1020', '02-1020', '91-1302', '91-2302', '23-1000', '01-9000',
          StrSubstNo(XConstTransMehSevManufMaint, '23'));
        InsertData('01-102_25', '01-1020', '02-1020', '01-1020', '02-1020', '91-1302', '91-2302', '25-1000', '01-9000',
          StrSubstNo(XConstTransMehManufOverheadCosts, '25'));
        InsertData('01-102_26', '01-1020', '02-1020', '01-1020', '02-1020', '91-1302', '91-2302', '26-5000', '01-9000',
          StrSubstNo(XConstTransMehDepr, '26'));
        InsertData('01-102_29', '01-1020', '02-1020', '01-1020', '02-1020', '91-1302', '91-2302', '29-1000', '01-9000',
          StrSubstNo(XConstTransMehSevManufMaint, '29'));
        InsertData('01-102_44', '01-1020', '02-1020', '01-1020', '02-1020', '91-1302', '91-2302', '44-2400', '01-9000',
          StrSubstNo(XConstTransMehDepr, '44'));
        InsertData('01-103_20', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '20-1400', '01-9000',
          StrSubstNo(XMachinesEquipDepr, '20'));
        InsertData('01-103_23', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '23-1000', '01-9000',
          StrSubstNo(XMachinesEquipAuxProduction, '20'));
        InsertData('01-103_25', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '25-1000', '01-9000',
          StrSubstNo(XMachinesEquipManufOverheadCosts, '25'));
        InsertData('01-103_26', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '26-5000', '01-9000',
          StrSubstNo(XMachinesEquipDepr, '26'));
        InsertData('01-103_29', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '29-1000', '01-9000',
          StrSubstNo(XMachinesEquipSevManufMaint, '29'));
        InsertData('01-103_44', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '44-2400', '01-9000',
          StrSubstNo(XMachinesEquipDepr, '44'));
        InsertData('01-103_91', '01-1030', '02-1030', '01-1030', '02-1030', '', '91-2390', '26-5000', '01-9000',
          StrSubstNo(XMachinesEquipDeprEarnGrat, '26'));
        InsertData('01-104_20', '01-1040', '02-1040', '01-1040', '02-1040', '91-1302', '91-2302', '20-1400', '01-9000',
          StrSubstNo(XVehiclesDepr, '20'));
        InsertData('01-104_23', '01-1040', '02-1040', '01-1040', '02-1040', '91-1302', '91-2302', '23-1000', '01-9000',
          StrSubstNo(XVehiclesAuxProd, '23'));
        InsertData('01-104_25', '01-1040', '02-1040', '01-1040', '02-1040', '91-1302', '91-2302', '25-1000', '01-9000',
          StrSubstNo(XVehiclesManufOverheadCosts, '25'));
        InsertData('01-104_26', '01-1040', '02-1040', '01-1040', '02-1040', '91-1302', '91-2302', '26-5000', '01-9000',
          StrSubstNo(XVehiclesDepr, '26'));
        InsertData('01-104_29', '01-1040', '02-1040', '01-1040', '02-1040', '91-1302', '91-2302', '29-1000', '01-9000',
          StrSubstNo(XVehiclesServManufAndMaint, '29'));
        InsertData('01-104_44', '01-1040', '02-1040', '01-1040', '02-1040', '91-1302', '91-2302', '44-2400', '01-9000',
          StrSubstNo(XVehiclesDepr, '44'));
        InsertData('01-105_20', '01-1050', '02-1050', '01-1050', '02-1050', '91-1302', '91-2302', '20-1400', '01-9000',
          StrSubstNo(XManufEquipDepr, '20'));
        InsertData('01-105_23', '01-1050', '02-1050', '01-1050', '02-1050', '91-1302', '91-2302', '23-1000', '01-9000',
          StrSubstNo(XManufEquipAuxProd, '23'));
        InsertData('01-105_25', '01-1050', '02-1050', '01-1050', '02-1050', '91-1302', '91-2302', '25-1000', '01-9000',
          StrSubstNo(XManufEquipManufOverheadCosts, '25'));
        InsertData('01-105_26', '01-1050', '02-1050', '01-1050', '02-1050', '91-1302', '91-2302', '26-5000', '01-9000',
          StrSubstNo(XManufEquipDepr, '26'));
        InsertData('01-105_29', '01-1050', '02-1050', '01-1050', '02-1050', '91-1302', '91-2302', '29-1000', '01-9000',
          StrSubstNo(XManufEquipServManufAndMaint, '29'));
        InsertData('01-105_44', '01-1050', '02-1050', '01-1050', '02-1050', '91-1302', '91-2302', '44-2400', '01-9000',
          StrSubstNo(XManufEquipDepr, '44'));
        InsertData('01-106_20', '01-1060', '02-1060', '01-1060', '02-1060', '91-1302', '91-2302', '20-1400', '01-9000',
          StrSubstNo(XPloughCattleDepr, '20'));
        InsertData('01-106_23', '01-1060', '02-1060', '01-1060', '02-1060', '91-1302', '91-2302', '23-1000', '01-9000',
          StrSubstNo(XPloughCattleAuxProd, '23'));
        InsertData('01-106_25', '01-1060', '02-1060', '01-1060', '02-1060', '91-1302', '91-2302', '25-1000', '01-9000',
          StrSubstNo(XPloughCattleManufOverheadCosts, '25'));
        InsertData('01-106_26', '01-1060', '02-1060', '01-1060', '02-1060', '91-1302', '91-2302', '26-5000', '01-9000',
          StrSubstNo(XPloughCattleDepr, '26'));
        InsertData('01-106_29', '01-1060', '02-1060', '01-1060', '02-1060', '91-1302', '91-2302', '29-1000', '01-9000',
          StrSubstNo(XPloughCattleServManufAndMaint, '29'));
        InsertData('01-106_44', '01-1060', '02-1060', '01-1060', '02-1060', '91-1302', '91-2302', '44-2400', '01-9000',
          StrSubstNo(XPloughCattleDepr, '44'));
        InsertData('01-107_20', '01-1070', '02-1070', '01-1070', '02-1070', '91-1302', '91-2302', '20-1400', '01-9000',
          StrSubstNo(XProductiveLivestockDepr, '20'));
        InsertData('01-107_23', '01-1070', '02-1070', '01-1070', '02-1070', '91-1302', '91-2302', '23-1000', '01-9000',
          StrSubstNo(XProductiveLivestockAuxProd, '23'));
        InsertData('01-107_25', '01-1070', '02-1070', '01-1070', '02-1070', '91-1302', '91-2302', '25-1000', '01-9000',
          StrSubstNo(XProductiveLivestockManufOverheadCosts, '25'));
        InsertData('01-107_26', '01-1070', '02-1070', '01-1070', '02-1070', '91-1302', '91-2302', '26-5000', '01-9000',
          StrSubstNo(XProductiveLivestockDepr, '26'));
        InsertData('01-107_29', '01-1070', '02-1070', '01-1070', '02-1070', '91-1302', '91-2302', '29-1000', '01-9000',
          StrSubstNo(XProductiveLivestockServManufAndMaint, '29'));
        InsertData('01-107_44', '01-1070', '02-1070', '01-1070', '02-1070', '91-1302', '91-2302', '44-2400', '01-9000',
          StrSubstNo(XProductiveLivestockDepr, '44'));
        InsertData('01-108_20', '01-1080', '02-1080', '01-1080', '02-1080', '91-1302', '91-2302', '20-1400', '01-9000',
          StrSubstNo(XPerenPlantDepr, '20'));
        InsertData('01-108_23', '01-1080', '02-1080', '01-1080', '02-1080', '91-1302', '91-2302', '23-1000', '01-9000',
          StrSubstNo(XPerenPlantAuxProd, '23'));
        InsertData('01-108_25', '01-1080', '02-1080', '01-1080', '02-1080', '91-1302', '91-2302', '25-1000', '01-9000',
          StrSubstNo(XPerenPlantManufOverheadCosts, '25'));
        InsertData('01-108_26', '01-1080', '02-1080', '01-1080', '02-1080', '91-1302', '91-2302', '26-5000', '01-9000',
          StrSubstNo(XPerenPlantDepr, '26'));
        InsertData('01-108_29', '01-1080', '02-1080', '01-1080', '02-1080', '91-1302', '91-2302', '29-1000', '01-9000',
          StrSubstNo(XPerenPlantServManufAndMaint, '29'));
        InsertData('01-108_44', '01-1080', '02-1080', '01-1080', '02-1080', '91-1302', '91-2302', '44-2400', '01-9000',
          StrSubstNo(XPerenPlantDepr, '4'));
        InsertData('01-109_20', '01-1090', '02-1090', '01-1090', '02-1090', '91-1302', '91-2302', '20-2990', '01-9000',
          StrSubstNo(XOtherTypesDepr, '20'));
        InsertData('01-109_23', '01-1090', '02-1090', '01-1090', '02-1090', '91-1302', '91-2302', '23-1000', '01-9000',
          StrSubstNo(XOtherTypesAuxProd, '23'));
        InsertData('01-109_25', '01-1090', '02-1090', '01-1090', '02-1090', '91-1302', '91-2302', '25-1000', '01-9000',
          StrSubstNo(XOtherTypesManufOverheadCosts, '25'));
        InsertData('01-109_26', '01-1090', '02-1090', '01-1090', '02-1090', '91-1302', '91-2302', '26-5000', '01-9000',
          StrSubstNo(XOtherTypesDepr, '26'));
        InsertData('01-109_29', '01-1090', '02-1090', '01-1090', '02-1090', '91-1302', '91-2302', '29-1000', '01-9000',
          StrSubstNo(XOtherTypesServManufAndMaint, '29'));
        InsertData('01-109_44', '01-1090', '02-1090', '01-1090', '02-1090', '91-1302', '91-2302', '44-2400', '01-9000',
          StrSubstNo(XOtherTypesDepr, '44'));
        InsertData('01-110_90', '01-1100', '', '01-1100', '', '90-1110', '90-2110', '', '01-9000',
          StrSubstNo(XLandEstates, '90'));
        InsertData('01-110_91', '01-1100', '', '01-1100', '', '91-1302', '91-2302', '', '01-9000',
          StrSubstNo(XLandEstates, '91'));
        InsertData('01-111_90', '01-1110', '', '01-1110', '', '90-1110', '90-2110', '', '01-9000',
          StrSubstNo(XCapitalInvestInLandUpgrd, '90'));
        InsertData('01-201_90', '01-2010', '02-2010', '01-2010', '02-2010', '91-1302', '91-2302', '90-2210', '01-9000',
          StrSubstNo(XBuildLeased, '90'));
        InsertData('01-201_91', '01-2010', '02-2010', '01-2010', '02-2010', '91-1302', '91-2302', '91-2301', '01-9000',
          StrSubstNo(XBuildLeased, '91'));
        InsertData('01-202_90', '01-2020', '02-2020', '01-2020', '02-2020', '91-1302', '91-2302', '90-2210', '01-9000',
          StrSubstNo(XConstAndTransMechLeased, '90'));
        InsertData('01-202_91', '01-2020', '02-2020', '01-2020', '02-2020', '91-1302', '91-2302', '91-2301', '01-9000',
          StrSubstNo(XConstAndTransMechLeased, '91'));
        InsertData('01-203_90', '01-2030', '02-2030', '01-2030', '02-2030', '91-1302', '91-2302', '90-2210', '01-9000',
          StrSubstNo(XMachinesAndEquipLeased, '90'));
        InsertData('01-203_91', '01-2030', '02-2030', '01-2030', '02-2030', '91-1302', '91-2302', '91-2301', '01-9000',
          StrSubstNo(XMachinesAndEquipLeased, '91'));
        InsertData('01-204_90', '01-2040', '02-2040', '01-2040', '02-2040', '91-1302', '91-2302', '90-2210', '01-9000',
          StrSubstNo(XVehiclesLeased, '90'));
        InsertData('01-204_91', '01-2040', '02-2040', '01-2040', '02-2040', '91-1302', '91-2302', '91-2301', '01-9000',
          StrSubstNo(XVehiclesLeased, '91'));
        InsertData('01-205_90', '01-2050', '02-2050', '01-2050', '02-2050', '91-1302', '91-2302', '90-2210', '01-9000',
          StrSubstNo(XManufEquipLeased, '90'));
        InsertData('01-205_91', '01-2050', '02-2050', '01-2050', '02-2050', '91-1302', '91-2302', '91-2301', '01-9000',
          StrSubstNo(XManufEquipLeased, '91'));
        InsertData('01-206_90', '01-2060', '02-2060', '01-2060', '02-2060', '91-1302', '91-2302', '90-2210', '01-9000',
          StrSubstNo(XPloughCattleLeased, '90'));
        InsertData('01-206_91', '01-2060', '02-2060', '01-2060', '02-2060', '91-1302', '91-2302', '91-2301', '01-9000',
          StrSubstNo(XPloughCattleLeased, '91'));
        InsertData('01-207_90', '01-2070', '02-2070', '01-2070', '02-2070', '91-1302', '91-2302', '90-2210', '01-9000',
          StrSubstNo(XProductiveLivestockLeased, '90'));
        InsertData('01-207_91', '01-2070', '02-2070', '01-2070', '02-2070', '91-1302', '91-2302', '91-2301', '01-9000',
          StrSubstNo(XProductiveLivestockLeased, '91'));
        InsertData('01-208_90', '01-2080', '02-2080', '01-2080', '02-2080', '91-1302', '91-2302', '90-2210', '01-9000',
          StrSubstNo(XPerenPlanLeased, '90'));
        InsertData('01-208_91', '01-2080', '02-2080', '01-2080', '02-2080', '91-1302', '91-2302', '91-2301', '01-9000',
          StrSubstNo(XPerenPlanLeased, '91'));
        InsertData('01-209_90', '01-2090', '02-2090', '01-2090', '02-2090', '91-1302', '91-2302', '90-2210', '01-9000',
          StrSubstNo(XOtherTypesLeased, '90'));
        InsertData('01-209_91', '01-2090', '02-2090', '01-2090', '02-2090', '91-1302', '91-2302', '91-2301', '01-9000',
          StrSubstNo(XOtherTypesLeased, '91'));
        InsertData('01-210_90', '', '01-2100', '', '01-2100', '91-1302', '91-2302', '90-2210', '01-9000',
          StrSubstNo(XLandEstatesLeased, '90'));
        InsertData('01-210_91', '', '01-2100', '', '01-2100', '91-1302', '91-2302', '91-2301', '01-9000',
          StrSubstNo(XLandEstatesLeased, '91'));
        InsertData('01-400', '01-4000', '02-4000', '', '', '', '', '', '01-9000',
          XFABeingPreserved);
        InsertData('01-500', '01-5000', '02-5000', '01-5000', '02-5000', '79-3000', '79-3000', '79-3000', '79-3000',
          XFABeingTrustManaged);
        InsertData('03-100_20', '03-1000', '02-6100', '03-1000', '02-6100', '90-1110', '90-2110', '20-1400', '03-9000',
          StrSubstNo(XDeprPropertyForLease, '20'));
        InsertData('03-100_23', '03-1000', '02-6100', '03-1000', '02-6100', '90-1110', '90-2110', '23-1000', '03-9000',
          StrSubstNo(XDeprPropertyForLease, '23'));
        InsertData('03-100_25', '03-1000', '02-6100', '03-1000', '02-6100', '90-1110', '90-2110', '25-1000', '03-9000',
          StrSubstNo(XDeprPropertyForLease, '25'));
        InsertData('03-100_26', '03-1000', '02-6100', '03-1000', '02-6100', '90-1110', '90-2110', '26-5000', '03-9000',
          StrSubstNo(XDeprPropertyForLease, '26'));
        InsertData('03-200_20', '03-2000', '02-6200', '03-2000', '02-6200', '91-1301', '91-2301', '20-1400', '03-9000',
          StrSubstNo(XDeprPropertyUnderRentAgr, '20'));
        InsertData('03-200_23', '03-2000', '02-6200', '03-2000', '02-6200', '91-1301', '91-2301', '23-1000', '03-9000',
          StrSubstNo(XDeprPropertyUnderRentAgr, '23'));
        InsertData('03-200_25', '03-2000', '02-6200', '03-2000', '02-6200', '91-1301', '91-2301', '25-1000', '03-9000',
          StrSubstNo(XDeprPropertyUnderRentAgr, '25'));
        InsertData('03-200_26', '03-2000', '02-6200', '03-2000', '02-6200', '91-1301', '91-2301', '26-5000', '03-9000',
          StrSubstNo(XDeprPropertyUnderRentAgr, '26'));
        InsertData('03-300_20', '03-3000', '02-6300', '03-3000', '02-6300', '91-1301', '91-2301', '20-1400', '03-9000',
          StrSubstNo(XOtherLucrInvest, '20'));
        InsertData('03-300_23', '03-3000', '02-6300', '03-3000', '02-6300', '91-1301', '91-2301', '23-1000', '03-9000',
          StrSubstNo(XOtherLucrInvest, '23'));
        InsertData('03-300_25', '03-3000', '02-6300', '03-3000', '02-6300', '91-1301', '91-2301', '25-1000', '03-9000',
          StrSubstNo(XOtherLucrInvest, '25'));
        InsertData('03-300_26', '03-3000', '02-6300', '03-3000', '02-6300', '91-1301', '91-2301', '26-5000', '03-9000',
          StrSubstNo(XOtherLucrInvest, '26'));
        InsertData('04-110_20', '04-1100', '05-1100', '04-1100', '05-1100', '91-1305', '91-2305', '20-1400', '',
          StrSubstNo(XIPRForInvManufPatModels, XDirectCosts, '20'));
        InsertData('04-110_26', '04-1100', '05-1100', '04-1100', '05-1100', '91-1305', '91-2305', '26-5000', '',
          StrSubstNo(XIPRForInvManufPatModels, XCosts, '26'));
        InsertData('04-110_44', '04-1100', '05-1100', '04-1100', '05-1100', '91-1305', '91-2305', '44-2400', '',
          StrSubstNo(XIPRForInvManufPatModels, XIndirectCosts, '44'));
        InsertData('04-120_20', '04-1200', '05-1200', '04-1200', '05-1200', '91-1305', '91-2305', '20-1400', '',
          StrSubstNo(XIPRForProgramsDB, XDirectCosts, '20'));
        InsertData('04-120_26', '04-1200', '05-1200', '04-1200', '05-1200', '91-1305', '91-2305', '26-5000', '',
          StrSubstNo(XIPRForProgramsDB, XCosts, '26'));
        InsertData('04-120_44', '04-1200', '05-1200', '04-1200', '05-1200', '91-1305', '91-2305', '44-2400', '',
          StrSubstNo(XIPRForProgramsDB, XIndirectCosts, '44'));
        InsertData('04-130_20', '04-1300', '05-1300', '04-1300', '05-1300', '91-1305', '91-2305', '20-1400', '',
          StrSubstNo(XIPRForIntegrCircLayout, XDirectCosts, '20'));
        InsertData('04-130_26', '04-1300', '05-1300', '04-1300', '05-1300', '91-1305', '91-2305', '26-5000', '',
          StrSubstNo(XIPRForIntegrCircLayout, XCosts, '26'));
        InsertData('04-130_44', '04-1300', '05-1300', '04-1300', '05-1300', '91-1305', '91-2305', '44-2400', '',
          StrSubstNo(XIPRForIntegrCircLayout, XIndirectCosts, '44'));
        InsertData('04-140_20', '04-1400', '05-1400', '04-1400', '05-1400', '91-1305', '91-2305', '20-1400', '',
          StrSubstNo(XIPRForTradmarkServMark, XDirectCosts, '20'));
        InsertData('04-140_26', '04-1400', '05-1400', '04-1400', '05-1400', '91-1305', '91-2305', '26-5000', '',
          StrSubstNo(XIPRForTradmarkServMark, XCosts, '26'));
        InsertData('04-140_44', '04-1400', '05-1400', '04-1400', '05-1400', '91-1305', '91-2305', '44-2400', '',
          StrSubstNo(XIPRForTradmarkServMark, XIndirectCosts, '44'));
        InsertData('04-150_20', '04-1500', '05-1500', '04-1500', '05-1500', '91-1305', '91-2305', '20-1400', '',
          StrSubstNo(XIASelectionPatent, XDirectCosts, '20'));
        InsertData('04-150_26', '04-1500', '05-1500', '04-1500', '05-1500', '91-1305', '91-2305', '26-5000', '',
          StrSubstNo(XIASelectionPatent, XCosts, '26'));
        InsertData('04-150_44', '04-1500', '05-1500', '04-1500', '05-1500', '91-1305', '91-2305', '44-2400', '',
          StrSubstNo(XIASelectionPatent, XIndirectCosts, '44'));
        InsertData('04-300_26', '04-3000', '', '04-3000', '', '91-1305', '91-2305', '26-9900', '',
          StrSubstNo(XIAKnowHow, '26'));
        InsertData('04-400_26', '04-4000', '04-4000', '04-4000', '04-4000', '91-1305', '91-2305', '26-9900', '',
          StrSubstNo(XIAGoodwill, '26'));
        InsertData('04-500_20', '04-5000', '04-5000', '04-5000', '04-5000', '91-1305', '91-2305', '20-2990', '',
          StrSubstNo(XIARD, '20'));
        InsertData('04-500_26', '04-5000', '04-5000', '04-5000', '04-5000', '91-1305', '91-2305', '26-9900', '',
          StrSubstNo(XIARD, '26'));
        InsertData('04-900_20', '04-9000', '05-9000', '04-9000', '05-9000', '91-1305', '91-2305', '20-2990', '',
          StrSubstNo(XIAOther, '20'));
        InsertData('04-900_23', '04-9000', '05-9000', '04-9000', '05-9000', '91-1305', '91-2305', '23-1000', '',
          StrSubstNo(XIAOther, '23'));
        InsertData('04-900_25', '04-9000', '05-9000', '04-9000', '05-9000', '91-1305', '91-2305', '25-1000', '',
          StrSubstNo(XIAOther, '25'));
        InsertData('04-900_26', '04-9000', '05-9000', '04-9000', '05-9000', '91-1305', '91-2305', '26-9900', '',
          StrSubstNo(XIAOther, '26'));
        InsertData('04-900_44', '04-9000', '05-9000', '04-9000', '05-9000', '91-1305', '91-2305', '44-2990', '',
          StrSubstNo(XIAOther, '44'));
        InsertData('07-100', '07-1000', '', '07-1000', '', '91-1305', '91-2305', '', '07-1000',
          XEquipForInstall);
        InsertData('08-100', '08-1000', '', '08-1000', '', '91-1305', '91-2305', '', '01-9000',
          XLandEstateAcq);
        InsertFACharge('08-100', XEXCLUDETA, XINCLUDETA);
        InsertData('08-200', '08-2000', '', '08-2000', '', '91-1305', '91-2305', '', '01-9000',
          XObjNatureMgtAcq);
        InsertFACharge('08-200', XEXCLUDETA, XINCLUDETA);
        InsertData('08-310', '08-3100', '', '', '', '', '', '', '',
          XConstUsingContrWork);
        InsertData('08-320', '08-3200', '', '', '', '', '', '', '',
          XSelfFinConst);
        InsertData('08-330', '08-3300', '', '', '', '', '', '', '',
          XExpensesToBeAllocated);
        InsertData('08-340', '08-3400', '', '', '', '', '', '', '',
          XEquipTransForAssembl);
        InsertData('08-400', '08-4000', '', '08-4000', '', '91-1305', '91-2305', '', '01-9000',
          XAcqOfFA);
        InsertFACharge('08-400', XEXCLUDETA, XINCLUDETA);
        InsertData('08-401', '08-4010', '', '', '', '', '', '', '',
          XAcqOfPropertyForFurtherLease);
        InsertData('08-500', '08-5000', '', '08-5000', '', '91-1305', '91-2305', '', '01-9000',
          XAcqOfIntangibleAssets);
        InsertFACharge('08-500', XEXCLUDETA, XINCLUDETA);
        InsertData('08-600', '08-6000', '', '', '', '', '', '', '',
          XTransYoungAnimalsIntoMainHerd);
        InsertData('08-700', '08-7000', '', '', '', '', '', '', '',
          XPurchMatureAnimals);
        InsertData('08-800', '08-8000', '', '', '', '', '', '', '',
          XPerformingRD);
        InsertData('08-900', '08-9000', '', '', '', '', '', '', '',
          XReconstOfFA);
        InsertData('97-130_20', '97-1300', '97-1300', '', '', '', '', '20-2980', '',
          StrSubstNo(XDefLessThenYear, '20'));
        InsertData('97-130_23', '97-1300', '97-1300', '', '', '', '', '23-1000', '',
          StrSubstNo(XDefLessThenYear, '23'));
        InsertData('97-130_25', '97-1300', '97-1300', '', '', '', '', '25-1000', '',
          StrSubstNo(XDefLessThenYear, '25'));
        InsertData('97-130_26', '97-1300', '97-1300', '', '', '', '', '26-9800', '',
          StrSubstNo(XDefLessThenYear, '26'));
        InsertData('97-130_44', '97-1300', '97-1300', '', '', '', '', '44-2980', '',
          StrSubstNo(XDefLessThenYear, '44'));
        InsertData('99-1010', '99-1010', '', '', '', '', '', '', '99-1010',
          '');
        InsertData(XTAX + '101', '', '99-6010', '', '', '', '', '99-5090', '',
          XBuildingDeprTA);
        InsertData(XTAX + '102', '', '99-6020', '', '', '', '', '99-5090', '',
          XConstAndTransMechanismsDeprTA);
        InsertData(XTAX + '103', '', '99-6030', '', '', '', '', '99-5090', '',
          XMachinesAndEquipDeprTA);
        InsertData(XTAX + '104', '', '99-6040', '', '', '', '', '99-5090', '',
          XVehiclesDeprTA);
        InsertData(XTAX + '105', '', '99-6050', '', '', '', '', '99-5090', '',
          XManufEquipDeprTA);
        InsertData(XTAX + '106', '', '99-6060', '', '', '', '', '99-5090', '',
          XPloughCattleDeprTA);
        InsertData(XTAX + '107', '', '99-6070', '', '', '', '', '99-5090', '',
          XProductiveLivestockDeprTA);
        InsertData(XTAX + '108', '', '99-6080', '', '', '', '', '99-5090', '',
          XPerenPlantDeprTA);
        InsertData(XTAX + '109', '', '99-6090', '', '', '', '', '99-5090', '',
          XOtherTypesDeprTA);
        InsertData(XTAX + XIA, '', '99-6095', '', '', '', '', '99-5090', '',
          '');
    end;

    var
        "FA Posting Group": Record "FA Posting Group";
        CA: Codeunit "Make Adjustments";
        XTAX: Label 'TAX-';
        XIA: Label 'IA';
        XEXCLUDETA: Label 'EXCLUDETA';
        XINCLUDETA: Label 'INCLUDETA';
        XEQUIPMENT: Label 'EQUIPMENT';
        XPATENTS: Label 'PATENTS';
        XGOODWILL: Label 'GOODWILL';
        XPLANT: Label 'PLANT';
        XPROPERTY: Label 'PROPERTY';
        XVEHICLES: Label 'VEHICLES';
        XFURNITUREFIXTURES: Label 'FURNITURE';
        XIP: Label 'IP';
        XBuildingDepreciation: Label 'Buildings depreciation %1 acc.';
        XAuxProduction: Label 'Auxiliary production %1 acc.';
        XManufOverheadCosts: Label 'Manufacturing overhead costs %1 acc.';
        XServManufAndMaint: Label 'Service manufacturing and maintenance %1 acc.';
        XConstAndTransMechanism: Label 'Constructions and transfer mechanisms %1 acc.';
        XConstTransMehSevManufMaint: Label 'Constr. and trans. mech. Serv. manuf/maint %1 acc.';
        XConstTransMehManufOverheadCosts: Label 'Constr. and trans. mech. Man. over. costs %1 acc.';
        XConstTransMehDepr: Label 'Constr. and trans. mech. Depreciation %1 acc.';
        XMachinesEquipDepr: Label 'Machines and equipment. Depreciation. %1 acc.';
        XMachinesEquipAuxProduction: Label 'Machines and equipment. Aux. production %1 acc.';
        XMachinesEquipManufOverheadCosts: Label 'Machines and equipment. Man. over. costs %1 acc.';
        XMachinesEquipSevManufMaint: Label 'Machines and equip. Serv. manuf/maint. %1 acc.';
        XMachinesEquipDeprEarnGrat: Label 'Mach. and equip. Depr. % 1 acc. (earned grat-ly)';
        XVehiclesDepr: Label 'Vehicles depreciation %1 acc.';
        XVehiclesAuxProd: Label 'Vehicles. Auxiliary production %1 acc.';
        XVehiclesManufOverheadCosts: Label 'Vehicles. Manufacturing overhead costs %1 acc.';
        XVehiclesServManufAndMaint: Label 'Vehicles. Serv. manuf. and maint. %1 acc.';
        XManufEquipDepr: Label 'Manuf. equipment. Depreciation %1 acc.';
        XManufEquipAuxProd: Label 'Manuf. equipment. Auxiliary production %1 acc.';
        XManufEquipManufOverheadCosts: Label 'Manuf. equipment. Manuf. over. costs %1 acc.';
        XManufEquipServManufAndMaint: Label 'Manuf. equip. Serv. manuf. and maint. %1 acc.';
        XPloughCattleDepr: Label 'Plough cattle. Depreciation %1 acc.';
        XPloughCattleAuxProd: Label 'Plough cattle. Auxiliary production %1 acc.';
        XPloughCattleManufOverheadCosts: Label 'Plough cattle. Manuf. overhead costs %1 acc.';
        XPloughCattleServManufAndMaint: Label 'Plough cattle. Serv. manuf. and maint. %1 acc.';
        XProductiveLivestockDepr: Label 'Productive livestock. Depreciation %1 acc.';
        XProductiveLivestockAuxProd: Label 'Productive livestock. Auxiliary production %1 acc.';
        XProductiveLivestockManufOverheadCosts: Label 'Prod. livestock. Manuf. overhead costs %1 acc.';
        XProductiveLivestockServManufAndMaint: Label 'Prod. livestock. Serv. manuf. and maint. %1 acc.';
        XPerenPlantDepr: Label 'Perennial plantations. Depreciation %1 acc.';
        XPerenPlantAuxProd: Label 'Perennial plantations. Aux. production %1 acc.';
        XPerenPlantManufOverheadCosts: Label 'Per. plantations. Manuf. over. costs %1 acc.';
        XPerenPlantServManufAndMaint: Label 'Per. plantations. Serv. manuf/maint. %1 acc.';
        XOtherTypesDepr: Label 'Other types. Depreciation %1 acc.';
        XOtherTypesAuxProd: Label 'Other types. Auxiliary production %1 acc.';
        XOtherTypesManufOverheadCosts: Label 'Other types. Manuf. overhead costs %1 acc.';
        XOtherTypesServManufAndMaint: Label 'Other types. Serv. manuf. and maint. %1 acc.';
        XLandEstates: Label 'Land and estates %1 acc.';
        XCapitalInvestInLandUpgrd: Label 'Capital investments in land upgrade %1 acc.';
        XBuildLeased: Label 'Buildings leased';
        XConstAndTransMechLeased: Label 'Constr-s and trans. mech. leased %1 acc.';
        XMachinesAndEquipLeased: Label 'Machines and equipment leased %1 acc.';
        XVehiclesLeased: Label 'Vehicles leased %1 acc.';
        XManufEquipLeased: Label 'Manufacturing equipment leased %1 acc.';
        XPloughCattleLeased: Label 'Plough cattle leased %1 acc.';
        XProductiveLivestockLeased: Label 'Productive livestoc leased %1 acc.';
        XPerenPlanLeased: Label 'Perennial plantations leased %1 acc.';
        XOtherTypesLeased: Label 'Other types leased %1 acc.';
        XLandEstatesLeased: Label 'Land and estates leased %1 acc.';
        XFABeingPreserved: Label 'FA being preserved';
        XFABeingTrustManaged: Label 'FA being trust managed';
        XDeprPropertyForLease: Label 'Depr. property for lease %1 acc.';
        XDeprPropertyUnderRentAgr: Label 'Depr. property under rental agr. %1 acc.';
        XOtherLucrInvest: Label 'Other lucrative investments %1 acc.';
        XIPRForInvManufPatModels: Label 'IPR for inv-s, man. patterns. %1 %2 acc.';
        XDirectCosts: Label 'Dir. costs';
        XCosts: Label 'Costs';
        XIndirectCosts: Label 'Ind. costs';
        XIPRForProgramsDB: Label 'IPR for programs, databases. %1 %2 acc.';
        XIPRForIntegrCircLayout: Label 'IPR for integr.-circuit layour. %1 %2 acc.';
        XIPRForTradmarkServMark: Label 'IPR for TM and serv. mark. %1 %2 acc.';
        XIASelectionPatent: Label 'IA Selection patent. %1 %2 acc.';
        XIAKnowHow: Label 'IA Know-how %1 acc.';
        XIAGoodwill: Label 'IA Goodwill %1 acc.';
        XIARD: Label 'IA R&D %1 acc.';
        XIAOther: Label 'IA Other %1 acc.';
        XEquipForInstall: Label 'Equipment for installation';
        XLandEstateAcq: Label 'Land and estate acquisition';
        XObjNatureMgtAcq: Label 'Objects of nature management acquisition';
        XConstUsingContrWork: Label 'Construction using contract work';
        XSelfFinConst: Label 'Self-financing construction';
        XExpensesToBeAllocated: Label 'Expenses to be allocated';
        XEquipTransForAssembl: Label 'Equipment transfered for assembling';
        XAcqOfFA: Label 'Acquisition of FA objects';
        XAcqOfPropertyForFurtherLease: Label 'Acq. of property (estate) for further lease';
        XAcqOfIntangibleAssets: Label 'Acquisition of intangible assets';
        XTransYoungAnimalsIntoMainHerd: Label 'Trans. young animals into main herd';
        XPurchMatureAnimals: Label 'Purchasing of mature animals';
        XPerformingRD: Label 'Performing R&D';
        XReconstOfFA: Label 'Reconstruction of fixed assets';
        XDefLessThenYear: Label 'Deferrals < 1 year, %1 acc.';
        XBuildingDeprTA: Label 'Buildings Depreciation TA';
        XConstAndTransMechanismsDeprTA: Label 'Constructions and trans. mechanisms. Depr. TA';
        XMachinesAndEquipDeprTA: Label 'Machines and equipment. Depreciation TA.';
        XVehiclesDeprTA: Label 'Vehicles. Depreciation TA.';
        XManufEquipDeprTA: Label 'Manufacturing equipment. Depreciation TA';
        XPloughCattleDeprTA: Label 'Plough cattle. Depreciation TA';
        XProductiveLivestockDeprTA: Label 'Productive livestock. Depreciation TA';
        XPerenPlantDeprTA: Label 'Perennial plantations. Depreciation TA';
        XOtherTypesDeprTA: Label 'Other types. Depreciation TA';

    procedure InsertData("Code": Code[10]; "Acquisition Cost Account": Code[20]; "Accum. Depreciation Account": Code[20]; "Acq. Cost Acc. on Disposal": Code[20]; "Accum. Depr. Acc. on Disposal": Code[20]; "Gains Acc. on Disposal": Code[20]; "Losses Acc. on Disposal": Code[20]; "Depreciation Expense Acc.": Code[20]; "Sales Balance Account": Code[20]; Description: Text[250])
    begin
        "FA Posting Group".Init();
        "FA Posting Group".Validate(Code, Code);
        "FA Posting Group".Validate("Acquisition Cost Account", CA.Convert("Acquisition Cost Account"));
        "FA Posting Group".Validate("Accum. Depreciation Account", CA.Convert("Accum. Depreciation Account"));
        "FA Posting Group".Validate("Acq. Cost Acc. on Disposal", CA.Convert("Acq. Cost Acc. on Disposal"));
        "FA Posting Group".Validate("Accum. Depr. Acc. on Disposal", CA.Convert("Accum. Depr. Acc. on Disposal"));
        "FA Posting Group".Validate("Gains Acc. on Disposal", CA.Convert("Gains Acc. on Disposal"));
        "FA Posting Group".Validate("Losses Acc. on Disposal", CA.Convert("Losses Acc. on Disposal"));
        "FA Posting Group".Validate("Maintenance Expense Account", CA.Convert("Acquisition Cost Account"));
        "FA Posting Group".Validate("Depreciation Expense Acc.", CA.Convert("Depreciation Expense Acc."));
        "FA Posting Group".Validate("Sales Bal. Acc.", CA.Convert("Sales Balance Account"));
        "FA Posting Group".Description := CopyStr(Description, MaxStrLen("FA Posting Group".Description));

        "FA Posting Group".Insert();
    end;

    procedure InsertDataKey("Code": Code[10])
    begin
        "FA Posting Group".Init();
        "FA Posting Group".Validate(Code, Code);
        "FA Posting Group".Insert();
    end;

    procedure InsertFACharge("Code": Code[10]; "Purch. PD Charge FCY (FA)": Code[10]; "Purch. PD Charge Conv. (FA)": Code[10])
    begin
        "FA Posting Group".Get(Code);
        "FA Posting Group"."Purch. PD Charge FCY (FA)" := "Purch. PD Charge FCY (FA)";
        "FA Posting Group"."Purch. PD Charge Conv. (FA)" := "Purch. PD Charge Conv. (FA)";
        "FA Posting Group".Modify();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData('01-101_20', '01-1010', '02-1010', '01-1010', '02-1010', '91-1302', '91-2302', '', '01-9000',
          StrSubstNo(XBuildingDepreciation, '20'));
        InsertData('01-103_20', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '', '01-9000',
          StrSubstNo(XMachinesEquipDepr, '20'));
        InsertData('01-104_20', '01-1040', '02-1040', '01-1040', '02-1040', '91-1302', '91-2302', '', '01-9000',
          StrSubstNo(XVehiclesDepr, '20'));
    end;

    procedure CreateTrialData()
    begin
        InsertData('01-103_20', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '', '01-9000', XPATENTS);
        InsertData('01-103_20', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '', '01-9000', XGOODWILL);
        InsertData('01-103_20', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '', '01-9000', XPLANT);
        InsertData('01-103_20', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '', '01-9000', XPROPERTY);
        InsertData('01-103_20', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '', '01-9000', XVEHICLES);
        InsertData('01-103_20', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '', '01-9000', XFURNITUREFIXTURES);
        InsertData('01-103_20', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '', '01-9000', XIP);

        InsertData('01-103_20', '01-1030', '02-1030', '01-1030', '02-1030', '91-1302', '91-2302', '', '01-9000', XEQUIPMENT);
    end;
}

