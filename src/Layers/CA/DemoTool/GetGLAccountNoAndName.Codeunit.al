codeunit 101016 "Get G/L Account No. and Name"
{
    procedure Assets(): Code[20]
    begin
        exit('10000');
    end;

    procedure CurrentAssets(): Code[20]
    begin
        exit('11000');
    end;

    procedure LiquidAssets(): Code[20]
    begin
        exit('11100');
    end;

    procedure Cash(): Code[20]
    begin
        exit('11110');
    end;

    procedure BankChecking(): Code[20]
    begin
        exit('11120');
    end;

    procedure BankCurrenciesLCY(): Code[20]
    begin
        exit('11130');
    end;

    procedure BankCurrenciesFCYUSD(): Code[20]
    begin
        exit('11140');
    end;

    procedure BankOperationsCash(): Code[20]
    begin
        exit('11150');
    end;

    procedure LiquidAssetsTotal(): Code[20]
    begin
        exit('11199');
    end;

    procedure Securities(): Code[20]
    begin
        exit('12000');
    end;

    procedure ShortTermInvestments(): Code[20]
    begin
        exit('12100');
    end;

    procedure CanadianTermDeposits(): Code[20]
    begin
        exit('12200');
    end;

    procedure Bonds(): Code[20]
    begin
        exit('12300');
    end;

    procedure OtherMarketableSecurities(): Code[20]
    begin
        exit('12400');
    end;

    procedure InterestAccruedoninvestment(): Code[20]
    begin
        exit('12500');
    end;

    procedure SecuritiesTotal(): Code[20]
    begin
        exit('12599');
    end;

    procedure AccountsReceivable(): Code[20]
    begin
        exit('13000');
    end;

    procedure CustomersDomesticCAD(): Code[20]
    begin
        exit('13100');
    end;

    procedure CustomersForeignFCY(): Code[20]
    begin
        exit('13200');
    end;

    procedure OtherReceivables(): Code[20]
    begin
        exit('13300');
    end;

    procedure AccountsReceivableTotal(): Code[20]
    begin
        exit('13400');
    end;

    procedure PurchasePrepayments(): Code[20]
    begin
        exit('13500');
    end;

    procedure VendorPrepaymentsServices(): Code[20]
    begin
        exit('13520');
    end;

    procedure VendorPrepaymentsRetail(): Code[20]
    begin
        exit('13530');
    end;

    procedure PurchasePrepaymentsTotal(): Code[20]
    begin
        exit('13540');
    end;

    procedure Inventory(): Code[20]
    begin
        exit('14000');
    end;

    procedure ResaleItems(): Code[20]
    begin
        exit('14100');
    end;

    procedure ResaleItemsInterim(): Code[20]
    begin
        exit('14101');
    end;

    procedure CostofResaleSoldInterim(): Code[20]
    begin
        exit('14102');
    end;

    procedure FinishedGoods(): Code[20]
    begin
        exit('14200');
    end;

    procedure FinishedGoodsInterim(): Code[20]
    begin
        exit('14201');
    end;

    procedure RawMaterials(): Code[20]
    begin
        exit('14300');
    end;

    procedure RawMaterialsInterim(): Code[20]
    begin
        exit('14301');
    end;

    procedure CostofRawMatSoldInterim(): Code[20]
    begin
        exit('14302');
    end;

    procedure PrimoInventory(): Code[20]
    begin
        exit('14400');
    end;

    procedure AllowanceforFinishedGoodsWriteOffs(): Code[20]
    begin
        exit('14450');
    end;

    procedure WIPAccountFinishedGoods(): Code[20]
    begin
        exit('14500');
    end;

    procedure InventoryTotal(): Code[20]
    begin
        exit('14600');
    end;

    procedure JobWIP(): Code[20]
    begin
        exit('15000');
    end;

    procedure WIPSales(): Code[20]
    begin
        exit('15010');
    end;

    procedure WIPJobSales(): Code[20]
    begin
        exit('15011');
    end;

    procedure InvoicedJobSales(): Code[20]
    begin
        exit('15012');
    end;

    procedure WIPSalesTotal(): Code[20]
    begin
        exit('15100');
    end;

    procedure WIPCosts(): Code[20]
    begin
        exit('15230');
    end;

    procedure WIPJobCosts(): Code[20]
    begin
        exit('15231');
    end;

    procedure AccruedJobCosts(): Code[20]
    begin
        exit('15232');
    end;

    procedure WIPCostsTotal(): Code[20]
    begin
        exit('15240');
    end;

    procedure JobWIPTotal(): Code[20]
    begin
        exit('15300');
    end;

    procedure CurrentAssetsTotal(): Code[20]
    begin
        exit('15950');
    end;

    procedure FixedAssets(): Code[20]
    begin
        exit('16000');
    end;

    procedure TangibleFixedAssets(): Code[20]
    begin
        exit('16100');
    end;

    procedure Vehicles(): Code[20]
    begin
        exit('16200');
    end;

    procedure Vehicle(): Code[20]
    begin
        exit('16210');
    end;

    procedure AccumDepreciationVehicles(): Code[20]
    begin
        exit('16300');
    end;

    procedure VehiclesTotal(): Code[20]
    begin
        exit('16400');
    end;

    procedure OperatingEquipment(): Code[20]
    begin
        exit('17000');
    end;

    procedure OperatEquipment(): Code[20]
    begin
        exit('17100');
    end;

    procedure AccumDeprOperEquip(): Code[20]
    begin
        exit('17200');
    end;

    procedure OperatingEquipmentTotal(): Code[20]
    begin
        exit('17300');
    end;

    procedure LandandBuildings(): Code[20]
    begin
        exit('18000');
    end;

    procedure LandandBuilding(): Code[20]
    begin
        exit('18100');
    end;

    procedure AccumDepreciationBuildings(): Code[20]
    begin
        exit('18200');
    end;

    procedure LandandBuildingsTotal(): Code[20]
    begin
        exit('18300');
    end;

    procedure TangibleFixedAssetsTotal(): Code[20]
    begin
        exit('18400');
    end;

    procedure IntangibleAssets(): Code[20]
    begin
        exit('18500');
    end;

    procedure IntangibleAsset(): Code[20]
    begin
        exit('18510');
    end;

    procedure AccAmortnonIntangibles(): Code[20]
    begin
        exit('18550');
    end;

    procedure IntangibleAssetsTotal(): Code[20]
    begin
        exit('18700');
    end;

    procedure FixedAssetsTotal(): Code[20]
    begin
        exit('18950');
    end;

    procedure TotalAssets(): Code[20]
    begin
        exit('19950');
    end;

    procedure LiabilitiesAndEquity(): Code[20]
    begin
        exit('20000');
    end;

    procedure Liabilities(): Code[20]
    begin
        exit('21000');
    end;

    procedure ShorttermLiabilities(): Code[20]
    begin
        exit('22000');
    end;

    procedure RevolvingCredit(): Code[20]
    begin
        exit('22100');
    end;

    procedure DeferredRevenue(): Code[20]
    begin
        exit('22140');
    end;

    procedure SalesPrepayments(): Code[20]
    begin
        exit('22150');
    end;

    procedure CustomerPrepaymentsServices(): Code[20]
    begin
        exit('22170');
    end;

    procedure CustomerPrepaymentsRetail(): Code[20]
    begin
        exit('22180');
    end;

    procedure PrepaidServiceContracts(): Code[20]
    begin
        exit('22181');
    end;

    procedure SalesPrepaymentsTotal(): Code[20]
    begin
        exit('22190');
    end;

    procedure AccountsPayable(): Code[20]
    begin
        exit('22200');
    end;

    procedure VendorsDomestic(): Code[20]
    begin
        exit('22300');
    end;

    procedure VendorsForeign(): Code[20]
    begin
        exit('22400');
    end;

    procedure AccountsPayableEmployees(): Code[20]
    begin
        exit('22420');
    end;

    procedure AccruedPayables(): Code[20]
    begin
        exit('22450');
    end;

    procedure AccountsPayableTotal(): Code[20]
    begin
        exit('22500');
    end;

    procedure InvAdjmtInterim(): Code[20]
    begin
        exit('22510');
    end;

    procedure InvAdjmtInterimRawMat(): Code[20]
    begin
        exit('22530');
    end;

    procedure InvAdjmtInterimRetail(): Code[20]
    begin
        exit('22550');
    end;

    procedure InvAdjmtInterimTotal(): Code[20]
    begin
        exit('22590');
    end;

    procedure TaxesPayables(): Code[20]
    begin
        exit('22600');
    end;

    procedure IncomeTaxPayable(): Code[20]
    begin
        exit('22610');
    end;

    procedure ProvincialSalesTax(): Code[20]
    begin
        exit('22700');
    end;

    procedure QSTSalesTaxCollected(): Code[20]
    begin
        exit('22740');
    end;

    procedure PurchaseTax(): Code[20]
    begin
        exit('22750');
    end;

    procedure GSTHSTSalesTax(): Code[20]
    begin
        exit('22780');
    end;

    procedure GSTHSTInputCredits(): Code[20]
    begin
        exit('22800');
    end;

    procedure IncomeTaxAccrued(): Code[20]
    begin
        exit('22810');
    end;

    procedure QuebecBeerTaxesAccrued(): Code[20]
    begin
        exit('22850');
    end;

    procedure TaxesPayablesTotal(): Code[20]
    begin
        exit('22899');
    end;

    procedure PrepaidHardwareContracts(): Code[20]
    begin
        exit('22960');
    end;

    procedure PrepaidSoftwareContracts(): Code[20]
    begin
        exit('22970');
    end;

    procedure TotalPrepaidServiceContract(): Code[20]
    begin
        exit('22990');
    end;

    procedure PersonnelrelatedItems(): Code[20]
    begin
        exit('23000');
    end;

    procedure AccruedSalariesWages(): Code[20]
    begin
        exit('23050');
    end;

    procedure FederalIncomeTaxExpense(): Code[20]
    begin
        exit('23100');
    end;

    procedure ProvincialWithholdingPayable(): Code[20]
    begin
        exit('23200');
    end;

    procedure PayrollTaxesPayable(): Code[20]
    begin
        exit('23300');
    end;

    procedure FICAPayable(): Code[20]
    begin
        exit('23400');
    end;

    procedure MedicarePayable(): Code[20]
    begin
        exit('23500');
    end;

    procedure FUTAPayable(): Code[20]
    begin
        exit('23600');
    end;

    procedure SUTAPayable(): Code[20]
    begin
        exit('23700');
    end;

    procedure EmployeeBenefitsPayable(): Code[20]
    begin
        exit('23750');
    end;

    procedure EmploymentInsuranceEmployeeContrib(): Code[20]
    begin
        exit('23760');
    end;

    procedure EmploymentInsuranceEmployerContrib(): Code[20]
    begin
        exit('23770');
    end;

    procedure CanadaPensionFundEmployeeContrib(): Code[20]
    begin
        exit('23780');
    end;

    procedure CanadaPensionFundEmployerContrib(): Code[20]
    begin
        exit('23790');
    end;

    procedure QuebecPIPPayableEmployee(): Code[20]
    begin
        exit('23795');
    end;

    procedure GarnishmentPayable(): Code[20]
    begin
        exit('23800');
    end;

    procedure VacationCompensationPayable(): Code[20]
    begin
        exit('23850');
    end;

    procedure EmployeesPayable(): Code[20]
    begin
        exit('23890');
    end;

    procedure TotalPersonnelrelatedItems(): Code[20]
    begin
        exit('23900');
    end;

    procedure OtherLiabilities(): Code[20]
    begin
        exit('24000');
    end;

    procedure DividendsfortheFiscalYear(): Code[20]
    begin
        exit('24200');
    end;

    procedure CorporateTaxesPayable(): Code[20]
    begin
        exit('24300');
    end;

    procedure OtherLiabilitiesTotal(): Code[20]
    begin
        exit('24400');
    end;

    procedure ShorttermLiabilitiesTotal(): Code[20]
    begin
        exit('24500');
    end;

    procedure LongtermLiabilities(): Code[20]
    begin
        exit('25000');
    end;

    procedure LongtermBankLoans(): Code[20]
    begin
        exit('25100');
    end;

    procedure Mortgage(): Code[20]
    begin
        exit('25200');
    end;

    procedure DeferredTaxes(): Code[20]
    begin
        exit('25300');
    end;

    procedure DeferralRevenue(): Code[20]
    begin
        exit('25301');
    end;

    procedure LongtermLiabilitiesTotal(): Code[20]
    begin
        exit('25400');
    end;

    procedure TotalLiabilities(): Code[20]
    begin
        exit('25995');
    end;

    procedure Equity(): Code[20]
    begin
        exit('30000');
    end;

    procedure CapitalStock(): Code[20]
    begin
        exit('30100');
    end;

    procedure RetainedEarnings(): Code[20]
    begin
        exit('30200');
    end;

    procedure NetIncomefortheYear(): Code[20]
    begin
        exit('30400');
    end;

    procedure TotalStockholdersEquity(): Code[20]
    begin
        exit('30500');
    end;

    procedure TotalLiabilitiesAndEquity(): Code[20]
    begin
        exit('39950');
    end;

    procedure IncomeStatement(): Code[20]
    begin
        exit('40000');
    end;

    procedure Revenue(): Code[20]
    begin
        exit('40100');
    end;

    procedure SalesofJobs(): Code[20]
    begin
        exit('43500');
    end;

    procedure SalesOtherJobExpenses(): Code[20]
    begin
        exit('44000');
    end;

    procedure JobSales(): Code[20]
    begin
        exit('44100');
    end;

    procedure TotalSalesofJobs(): Code[20]
    begin
        exit('44300');
    end;

    procedure SalesofServiceContracts(): Code[20]
    begin
        exit('44399');
    end;

    procedure ServiceContractSale(): Code[20]
    begin
        exit('44400');
    end;

    procedure TotalSaleofServContracts(): Code[20]
    begin
        exit('44500');
    end;

    procedure SalesofResources(): Code[20]
    begin
        exit('42500');
    end;

    procedure SalesResourcesDom(): Code[20]
    begin
        exit('43000');
    end;

    procedure SalesResourcesExport(): Code[20]
    begin
        exit('43100');
    end;

    procedure JobSalesAdjmtResources(): Code[20]
    begin
        exit('43300');
    end;

    procedure TotalSalesofResources(): Code[20]
    begin
        exit('43400');
    end;

    procedure SalesofRawMaterials(): Code[20]
    begin
        exit('41500');
    end;

    procedure SalesRawMaterialsDom(): Code[20]
    begin
        exit('42000');
    end;

    procedure SalesRawMaterialsExport(): Code[20]
    begin
        exit('42100');
    end;

    procedure JobSalesAdjmtRawMat(): Code[20]
    begin
        exit('42300');
    end;

    procedure TotalSalesofRawMaterials(): Code[20]
    begin
        exit('42400');
    end;

    procedure SalesofRetail(): Code[20]
    begin
        exit('41000');
    end;

    procedure SalesRetailDom(): Code[20]
    begin
        exit('41100');
    end;

    procedure SalesRetailExport(): Code[20]
    begin
        exit('41200');
    end;

    procedure JobSalesAppliedRetail(): Code[20]
    begin
        exit('41300');
    end;

    procedure JobSalesAdjmtRetail(): Code[20]
    begin
        exit('41400');
    end;

    procedure TotalSalesofRetail(): Code[20]
    begin
        exit('41450');
    end;

    procedure InterestIncome(): Code[20]
    begin
        exit('47000');
    end;

    procedure InterestonBankBalances(): Code[20]
    begin
        exit('47100');
    end;

    procedure FinanceChargesfromCustomers(): Code[20]
    begin
        exit('47200');
    end;

    procedure PmtDiscReceivedDecreases(): Code[20]
    begin
        exit('47260');
    end;

    procedure PaymentDiscountsReceived(): Code[20]
    begin
        exit('47300');
    end;

    procedure InvoiceRounding(): Code[20]
    begin
        exit('47400');
    end;

    procedure ApplicationRounding(): Code[20]
    begin
        exit('47500');
    end;

    procedure PaymentToleranceReceived(): Code[20]
    begin
        exit('47510');
    end;

    procedure PmtTolReceivedDecreases(): Code[20]
    begin
        exit('47520');
    end;

    procedure ConsultingFeesDom(): Code[20]
    begin
        exit('48000');
    end;

    procedure FeesandChargesRecDom(): Code[20]
    begin
        exit('48100');
    end;

    procedure DiscountGranted(): Code[20]
    begin
        exit('48200');
    end;

    procedure TotalInterestIncome(): Code[20]
    begin
        exit('48500');
    end;

    procedure TotalRevenue(): Code[20]
    begin
        exit('49950');
    end;

    procedure Cost(): Code[20]
    begin
        exit('50000');
    end;

    procedure JobCosts(): Code[20]
    begin
        exit('51000');
    end;

    procedure CostofResources(): Code[20]
    begin
        exit('52000');
    end;

    procedure CostofResourcesUsed(): Code[20]
    begin
        exit('52200');
    end;

    procedure JobCostAdjmtResources(): Code[20]
    begin
        exit('52210');
    end;

    procedure JobCostAppliedResources(): Code[20]
    begin
        exit('52211');
    end;

    procedure TotalCostofResources(): Code[20]
    begin
        exit('52300');
    end;

    procedure CostofCapacities(): Code[20]
    begin
        exit('52400');
    end;

    procedure CostofCapacitie(): Code[20]
    begin
        exit('52410');
    end;

    procedure DirectCostAppliedCap(): Code[20]
    begin
        exit('52450');
    end;

    procedure OverheadAppliedCap(): Code[20]
    begin
        exit('52460');
    end;

    procedure PurchaseVarianceCap(): Code[20]
    begin
        exit('52475');
    end;

    procedure TotalCostofCapacities(): Code[20]
    begin
        exit('52500');
    end;

    procedure CostofRawMaterials(): Code[20]
    begin
        exit('53000');
    end;

    procedure PurchRawMaterialsDom(): Code[20]
    begin
        exit('53100');
    end;

    procedure PurchRawMaterialsExport(): Code[20]
    begin
        exit('53200');
    end;

    procedure DiscReceivedRawMaterials(): Code[20]
    begin
        exit('53300');
    end;

    procedure DeliveryExpensesRawMat(): Code[20]
    begin
        exit('53350');
    end;

    procedure InventoryAdjmtRawMat(): Code[20]
    begin
        exit('53400');
    end;

    procedure DeliveryExpensesRetail(): Code[20]
    begin
        exit('54550');
    end;

    procedure JobCostAdjmtRawMaterials(): Code[20]
    begin
        exit('53499');
    end;

    procedure JobCostAppliedRawMaterials(): Code[20]
    begin
        exit('53500');
    end;

    procedure CostofRawMaterialsSold(): Code[20]
    begin
        exit('53600');
    end;

    procedure DirectCostAppliedRawmat(): Code[20]
    begin
        exit('53700');
    end;

    procedure OverheadAppliedRawmat(): Code[20]
    begin
        exit('53800');
    end;

    procedure PurchaseVarianceRawmat(): Code[20]
    begin
        exit('53850');
    end;

    procedure TotalCostofRawMaterials(): Code[20]
    begin
        exit('53900');
    end;

    procedure CostofRetail(): Code[20]
    begin
        exit('54000');
    end;

    procedure PurchRetailDom(): Code[20]
    begin
        exit('54100');
    end;

    procedure PurchRetailExport(): Code[20]
    begin
        exit('54300');
    end;

    procedure DiscReceivedRetail(): Code[20]
    begin
        exit('54400');
    end;

    procedure InventoryAdjmtRetail(): Code[20]
    begin
        exit('54500');
    end;

    procedure JobCostAppliedRetail(): Code[20]
    begin
        exit('54599');
    end;

    procedure JobCostAdjmtRetail(): Code[20]
    begin
        exit('54600');
    end;

    procedure CostofRetailSold(): Code[20]
    begin
        exit('54700');
    end;

    procedure OverheadAppliedRetail(): Code[20]
    begin
        exit('54702');
    end;

    procedure PurchaseVarianceRetail(): Code[20]
    begin
        exit('54703');
    end;

    procedure DirectCostAppliedRetail(): Code[20]
    begin
        exit('54710');
    end;

    procedure PaymentDiscountsGranted(): Code[20]
    begin
        exit('54800');
    end;

    procedure TotalCostofRetail(): Code[20]
    begin
        exit('54900');
    end;

    procedure Variance(): Code[20]
    begin
        exit('57000');
    end;

    procedure MaterialVariance(): Code[20]
    begin
        exit('57100');
    end;

    procedure CapacityVariance(): Code[20]
    begin
        exit('57200');
    end;

    procedure SubcontractedVariance(): Code[20]
    begin
        exit('57210');
    end;

    procedure CapOverheadVariance(): Code[20]
    begin
        exit('57300');
    end;

    procedure MfgOverheadVariance(): Code[20]
    begin
        exit('57400');
    end;

    procedure TotalVariance(): Code[20]
    begin
        exit('57900');
    end;

    procedure TotalCost(): Code[20]
    begin
        exit('59950');
    end;

    procedure OperatingExpenses(): Code[20]
    begin
        exit('60000');
    end;

    procedure SellingExpenses(): Code[20]
    begin
        exit('61000');
    end;

    procedure Advertising(): Code[20]
    begin
        exit('61100');
    end;

    procedure EntertainmentandPR(): Code[20]
    begin
        exit('61200');
    end;

    procedure Travel(): Code[20]
    begin
        exit('61300');
    end;

    procedure DeliveryExpenses(): Code[20]
    begin
        exit('61350');
    end;

    procedure TotalSellingExpenses(): Code[20]
    begin
        exit('61400');
    end;

    procedure PersonnelExpenses(): Code[20]
    begin
        exit('62000');
    end;

    procedure Wages(): Code[20]
    begin
        exit('62100');
    end;

    procedure Salaries(): Code[20]
    begin
        exit('62200');
    end;

    procedure RetirementPlanContributions(): Code[20]
    begin
        exit('62300');
    end;

    procedure VacationCompensation(): Code[20]
    begin
        exit('62400');
    end;

    procedure PayrollTaxes(): Code[20]
    begin
        exit('62500');
    end;

    procedure HealthInsurance(): Code[20]
    begin
        exit('62600');
    end;

    procedure GroupLifeInsurance(): Code[20]
    begin
        exit('62700');
    end;

    procedure WorkersCompensation(): Code[20]
    begin
        exit('62800');
    end;

    procedure KContributions(): Code[20]
    begin
        exit('62900');
    end;

    procedure TotalPersonnelExpenses(): Code[20]
    begin
        exit('62950');
    end;

    procedure VehicleExpenses(): Code[20]
    begin
        exit('63000');
    end;

    procedure GasolineandMotorOil(): Code[20]
    begin
        exit('63100');
    end;

    procedure RegistrationFees(): Code[20]
    begin
        exit('63200');
    end;

    procedure RepairsandMaintenance(): Code[20]
    begin
        exit('63300');
    end;

    procedure Taxes(): Code[20]
    begin
        exit('63450');
    end;

    procedure TotalVehicleExpenses(): Code[20]
    begin
        exit('63500');
    end;

    procedure ComputerExpenses(): Code[20]
    begin
        exit('64000');
    end;

    procedure Software(): Code[20]
    begin
        exit('64100');
    end;

    procedure ConsultantServices(): Code[20]
    begin
        exit('64200');
    end;

    procedure OtherComputerExpenses(): Code[20]
    begin
        exit('64300');
    end;

    procedure TotalComputerExpenses(): Code[20]
    begin
        exit('64400');
    end;

    procedure BuildingMaintenanceExpenses(): Code[20]
    begin
        exit('65000');
    end;

    procedure Cleaning(): Code[20]
    begin
        exit('65100');
    end;

    procedure ElectricityandHeating(): Code[20]
    begin
        exit('65200');
    end;

    procedure RepairAndMaintenance(): Code[20]
    begin
        exit('65300');
    end;

    procedure TotalBldgMaintExpenses(): Code[20]
    begin
        exit('65400');
    end;

    procedure AdministrativeExpenses(): Code[20]
    begin
        exit('65500');
    end;

    procedure OfficeSupplies(): Code[20]
    begin
        exit('65600');
    end;

    procedure PhoneandFax(): Code[20]
    begin
        exit('65700');
    end;

    procedure Postage(): Code[20]
    begin
        exit('65800');
    end;

    procedure TotalAdministrativeExpenses(): Code[20]
    begin
        exit('65900');
    end;

    procedure OtherOperatingExpenses(): Code[20]
    begin
        exit('67000');
    end;

    procedure CashDiscrepancies(): Code[20]
    begin
        exit('67100');
    end;

    procedure BadDebtExpenses(): Code[20]
    begin
        exit('67200');
    end;

    procedure LegalandAccountingServices(): Code[20]
    begin
        exit('67300');
    end;

    procedure Miscellaneous(): Code[20]
    begin
        exit('67400');
    end;

    procedure OtherCostsofOperations(): Code[20]
    begin
        exit('67500');
    end;

    procedure OtherOperatingExpTotal(): Code[20]
    begin
        exit('67600');
    end;

    procedure TotalOperatingExpenses(): Code[20]
    begin
        exit('69950');
    end;

    procedure EBITDA(): Code[20]
    begin
        exit('70000');
    end;

    procedure DepreciationofFixedAssets(): Code[20]
    begin
        exit('71000');
    end;

    procedure DepreciationBuildings(): Code[20]
    begin
        exit('71100');
    end;

    procedure DepreciationEquipment(): Code[20]
    begin
        exit('71200');
    end;

    procedure DepreciationVehicles(): Code[20]
    begin
        exit('71300');
    end;

    procedure TotalFixedAssetDepreciation(): Code[20]
    begin
        exit('71400');
    end;

    procedure InterestExpenses(): Code[20]
    begin
        exit('71500');
    end;

    procedure InterestonRevolvingCredit(): Code[20]
    begin
        exit('71600');
    end;

    procedure InterestonBankLoans(): Code[20]
    begin
        exit('71700');
    end;

    procedure MortgageInterest(): Code[20]
    begin
        exit('71800');
    end;

    procedure FinanceChargestoVendors(): Code[20]
    begin
        exit('71900');
    end;

    procedure PmtDiscGrantedDecreases(): Code[20]
    begin
        exit('72000');
    end;

    procedure PaymentToleranceGranted(): Code[20]
    begin
        exit('72100');
    end;

    procedure PaymentDiscountGranted(): Code[20]
    begin
        exit('72101');
    end;

    procedure PmtTolGrantedDecreases(): Code[20]
    begin
        exit('72200');
    end;

    procedure TotalInterestExpenses(): Code[20]
    begin
        exit('72300');
    end;

    procedure GainsAndLosses(): Code[20]
    begin
        exit('72400');
    end;

    procedure UnrealizedFXGains(): Code[20]
    begin
        exit('72500');
    end;

    procedure UnrealizedFXLosses(): Code[20]
    begin
        exit('72600');
    end;

    procedure RealizedFXGains(): Code[20]
    begin
        exit('72700');
    end;

    procedure RealizedFXLosses(): Code[20]
    begin
        exit('72800');
    end;

    procedure GainsandLosse(): Code[20]
    begin
        exit('72900');
    end;

    procedure TotalGainsAndLosses(): Code[20]
    begin
        exit('73000');
    end;

    procedure NetOperatingIncomeBeforeExtraOrdItemsTaxes(): Code[20]
    begin
        exit('74000');
    end;

    procedure IncomeTaxes(): Code[20]
    begin
        exit('75000');
    end;

    procedure CorporateTax(): Code[20]
    begin
        exit('76000');
    end;

    procedure StateIncomeTax(): Code[20]
    begin
        exit('76100');
    end;

    procedure TotalIncomeTaxes(): Code[20]
    begin
        exit('76200');
    end;

    procedure NetIncomeBeforeExtrItems(): Code[20]
    begin
        exit('80000');
    end;

    procedure ExtraordinaryItems(): Code[20]
    begin
        exit('81000');
    end;

    procedure ExtraordinaryIncome(): Code[20]
    begin
        exit('81100');
    end;

    procedure RevaluationSurplusadjustments(): Code[20]
    begin
        exit('81200');
    end;

    procedure ExtraordinaryExpenses(): Code[20]
    begin
        exit('81300');
    end;

    procedure ExtraordinaryItemsTotal(): Code[20]
    begin
        exit('81400');
    end;

    procedure AssetsName(): Text[100]
    begin
        exit(ASSETSTok);
    end;

    procedure CurrentAssetsName(): Text[100]
    begin
        exit(CurrentAssetsTok);
    end;

    procedure LiquidAssetsName(): Text[100]
    begin
        exit(LiquidAssetsTok);
    end;

    procedure CashName(): Text[100]
    begin
        exit(CashTok);
    end;

    procedure BankCheckingName(): Text[100]
    begin
        exit(BankCheckingTok);
    end;

    procedure BankCurrenciesLCYName(): Text[100]
    begin
        exit(BankCurrenciesLCYTok);
    end;

    procedure BankCurrenciesFCYUSDName(): Text[100]
    begin
        exit(BankCurrenciesFCYUSDTok);
    end;

    procedure BankOperationsCashName(): Text[100]
    begin
        exit(BankOperationsCashTok);
    end;

    procedure LiquidAssetsTotalName(): Text[100]
    begin
        exit(LiquidAssetsTotalTok);
    end;

    procedure SecuritiesName(): Text[100]
    begin
        exit(SecuritiesTok);
    end;

    procedure ShortTermInvestmentsName(): Text[100]
    begin
        exit(ShortTermInvestmentsTok);
    end;

    procedure CanadianTermDepositsName(): Text[100]
    begin
        exit(CanadianTermDepositsTok);
    end;

    procedure BondsName(): Text[100]
    begin
        exit(BondsTok);
    end;

    procedure OtherMarketableSecuritiesName(): Text[100]
    begin
        exit(OtherMarketableSecuritiesTok);
    end;

    procedure InterestAccruedoninvestmentName(): Text[100]
    begin
        exit(InterestAccruedoninvestmentTok);
    end;

    procedure SecuritiesTotalName(): Text[100]
    begin
        exit(SecuritiesTotalTok);
    end;

    procedure AccountsReceivableName(): Text[100]
    begin
        exit(AccountsReceivableTok);
    end;

    procedure CustomersDomesticCADName(): Text[100]
    begin
        exit(CustomersDomesticCADTok);
    end;

    procedure CustomersForeignFCYName(): Text[100]
    begin
        exit(CustomersForeignFCYTok);
    end;

    procedure OtherReceivablesName(): Text[100]
    begin
        exit(OtherReceivablesTok);
    end;

    procedure AccountsReceivableTotalName(): Text[100]
    begin
        exit(AccountsReceivableTotalTok);
    end;

    procedure PurchasePrepaymentsName(): Text[100]
    begin
        exit(PurchasePrepaymentsTok);
    end;

    procedure VendorPrepaymentsSERVICESName(): Text[100]
    begin
        exit(VendorPrepaymentsSERVICESTok);
    end;

    procedure VendorPrepaymentsRETAILName(): Text[100]
    begin
        exit(VendorPrepaymentsRETAILTok);
    end;

    procedure PurchasePrepaymentsTotalName(): Text[100]
    begin
        exit(PurchasePrepaymentsTotalTok);
    end;

    procedure InventoryName(): Text[100]
    begin
        exit(InventoryTok);
    end;

    procedure ResaleItemsName(): Text[100]
    begin
        exit(ResaleItemsTok);
    end;

    procedure ResaleItemsInterimName(): Text[100]
    begin
        exit(ResaleItemsInterimTok);
    end;

    procedure CostofResaleSoldInterimName(): Text[100]
    begin
        exit(CostofResaleSoldInterimTok);
    end;

    procedure FinishedGoodsName(): Text[100]
    begin
        exit(FinishedGoodsTok);
    end;

    procedure FinishedGoodsInterimName(): Text[100]
    begin
        exit(FinishedGoodsInterimTok);
    end;

    procedure RawMaterialsName(): Text[100]
    begin
        exit(RawMaterialsTok);
    end;

    procedure RawMaterialsInterimName(): Text[100]
    begin
        exit(RawMaterialsInterimTok);
    end;

    procedure CostofRawMatSoldInterimName(): Text[100]
    begin
        exit(CostofRawMatSoldInterimTok);
    end;

    procedure PrimoInventoryName(): Text[100]
    begin
        exit(PrimoInventoryTok);
    end;

    procedure AllowanceforFinishedGoodsWriteOffsName(): Text[100]
    begin
        exit(AllowanceforFinishedGoodsWriteOffsTok);
    end;

    procedure WIPAccountFinishedgoodsName(): Text[100]
    begin
        exit(WIPAccountFinishedgoodsTok);
    end;

    procedure InventoryTotalName(): Text[100]
    begin
        exit(InventoryTotalTok);
    end;

    procedure JobWIPName(): Text[100]
    begin
        exit(JobWIPTok);
    end;

    procedure WIPSalesName(): Text[100]
    begin
        exit(WIPSalesTok);
    end;

    procedure WIPJobSalesName(): Text[100]
    begin
        exit(WIPJobSalesTok);
    end;

    procedure InvoicedJobSalesName(): Text[100]
    begin
        exit(InvoicedJobSalesTok);
    end;

    procedure WIPSalesTotalName(): Text[100]
    begin
        exit(WIPSalesTotalTok);
    end;

    procedure WIPCostsName(): Text[100]
    begin
        exit(WIPCostsTok);
    end;

    procedure WIPJobCostsName(): Text[100]
    begin
        exit(WIPJobCostsTok);
    end;

    procedure AccruedJobCostsName(): Text[100]
    begin
        exit(AccruedJobCostsTok);
    end;

    procedure WIPCostsTotalName(): Text[100]
    begin
        exit(WIPCostsTotalTok);
    end;

    procedure JobWIPTotalName(): Text[100]
    begin
        exit(JobWIPTotalTok);
    end;

    procedure CurrentAssetsTotalName(): Text[100]
    begin
        exit(CurrentAssetsTotalTok);
    end;

    procedure FixedAssetsName(): Text[100]
    begin
        exit(FixedAssetsTok);
    end;

    procedure TangibleFixedAssetsName(): Text[100]
    begin
        exit(TangibleFixedAssetsTok);
    end;

    procedure VehiclesName(): Text[100]
    begin
        exit(VehiclesTok);
    end;

    procedure AccumDepreciationVehiclesName(): Text[100]
    begin
        exit(AccumDepreciationVehiclesTok);
    end;

    procedure VehiclesTotalName(): Text[100]
    begin
        exit(VehiclesTotalTok);
    end;

    procedure OperatingEquipmentName(): Text[100]
    begin
        exit(OperatingEquipmentTok);
    end;

    procedure AccumDeprOperEquipName(): Text[100]
    begin
        exit(AccumDeprOperEquipTok);
    end;

    procedure OperatingEquipmentTotalName(): Text[100]
    begin
        exit(OperatingEquipmentTotalTok);
    end;

    procedure LandandBuildingsName(): Text[100]
    begin
        exit(LandandBuildingsTok);
    end;

    procedure AccumDepreciationBuildingsName(): Text[100]
    begin
        exit(AccumDepreciationBuildingsTok);
    end;

    procedure LandandBuildingsTotalName(): Text[100]
    begin
        exit(LandandBuildingsTotalTok);
    end;

    procedure TangibleFixedAssetsTotalName(): Text[100]
    begin
        exit(TangibleFixedAssetsTotalTok);
    end;

    procedure IntangibleAssetsName(): Text[100]
    begin
        exit(IntangibleAssetsTok);
    end;

    procedure AccAmortnonIntangiblesName(): Text[100]
    begin
        exit(AccAmortnonIntangiblesTok);
    end;

    procedure IntangibleAssetsTotalName(): Text[100]
    begin
        exit(IntangibleAssetsTotalTok);
    end;

    procedure FixedAssetsTotalName(): Text[100]
    begin
        exit(FixedAssetsTotalTok);
    end;

    procedure TotalAssetsName(): Text[100]
    begin
        exit(TOTALASSETSTok);
    end;

    procedure LiabilitiesAndEquityName(): Text[100]
    begin
        exit(LIABILITIESANDEQUITYTok);
    end;

    procedure LiabilitiesName(): Text[100]
    begin
        exit(LiabilitiesTok);
    end;

    procedure ShorttermLiabilitiesName(): Text[100]
    begin
        exit(ShorttermLiabilitiesTok);
    end;

    procedure RevolvingCreditName(): Text[100]
    begin
        exit(RevolvingCreditTok);
    end;

    procedure DeferredRevenueName(): Text[100]
    begin
        exit(DeferredRevenueTok);
    end;

    procedure SalesPrepaymentsName(): Text[100]
    begin
        exit(SalesPrepaymentsTok);
    end;

    procedure CustomerPrepaymentsSERVICESName(): Text[100]
    begin
        exit(CustomerPrepaymentsSERVICESTok);
    end;

    procedure CustomerPrepaymentsRETAILName(): Text[100]
    begin
        exit(CustomerPrepaymentsRETAILTok);
    end;

    procedure SalesPrepaymentsTotalName(): Text[100]
    begin
        exit(SalesPrepaymentsTotalTok);
    end;

    procedure AccountsPayableName(): Text[100]
    begin
        exit(AccountsPayableTok);
    end;

    procedure VendorsDomesticName(): Text[100]
    begin
        exit(VendorsDomesticTok);
    end;

    procedure VendorsForeignName(): Text[100]
    begin
        exit(VendorsForeignTok);
    end;

    procedure AccountsPayableEmployeesName(): Text[100]
    begin
        exit(AccountsPayableEmployeesTok);
    end;

    procedure AccruedPayablesName(): Text[100]
    begin
        exit(AccruedPayablesTok);
    end;

    procedure AccountsPayableTotalName(): Text[100]
    begin
        exit(AccountsPayableTotalTok);
    end;

    procedure InvAdjmtInterimName(): Text[100]
    begin
        exit(InvAdjmtInterimTok);
    end;

    procedure InvAdjmtInterimRawMatName(): Text[100]
    begin
        exit(InvAdjmtInterimRawMatTok);
    end;

    procedure InvAdjmtInterimRetailName(): Text[100]
    begin
        exit(InvAdjmtInterimRetailTok);
    end;

    procedure InvAdjmtInterimTotalName(): Text[100]
    begin
        exit(InvAdjmtInterimTotalTok);
    end;

    procedure TaxesPayablesName(): Text[100]
    begin
        exit(TaxesPayablesTok);
    end;

    procedure IncomeTaxPayableName(): Text[100]
    begin
        exit(IncomeTaxPayableTok);
    end;

    procedure ProvincialSalesTaxName(): Text[100]
    begin
        exit(ProvincialSalesTaxTok);
    end;

    procedure QSTSalesTaxCollectedName(): Text[100]
    begin
        exit(QSTSalesTaxCollectedTok);
    end;

    procedure PurchaseTaxName(): Text[100]
    begin
        exit(PurchaseTaxTok);
    end;

    procedure GSTHSTSalesTaxName(): Text[100]
    begin
        exit(GSTHSTSalesTaxTok);
    end;

    procedure GSTHSTInputCreditsName(): Text[100]
    begin
        exit(GSTHSTInputCreditsTok);
    end;

    procedure IncomeTaxAccruedName(): Text[100]
    begin
        exit(IncomeTaxAccruedTok);
    end;

    procedure QuebecBeerTaxesAccruedName(): Text[100]
    begin
        exit(QuebecBeerTaxesAccruedTok);
    end;

    procedure TaxesPayablesTotalName(): Text[100]
    begin
        exit(TaxesPayablesTotalTok);
    end;

    procedure PrepaidServiceContractsName(): Text[100]
    begin
        exit(PrepaidServiceContractsTok);
    end;

    procedure PrepaidHardwareContractsName(): Text[100]
    begin
        exit(PrepaidHardwareContractsTok);
    end;

    procedure PrepaidSoftwareContractsName(): Text[100]
    begin
        exit(PrepaidSoftwareContractsTok);
    end;

    procedure TotalPrepaidServiceContractName(): Text[100]
    begin
        exit(TotalPrepaidServiceContractTok);
    end;

    procedure PersonnelrelatedItemsName(): Text[100]
    begin
        exit(PersonnelrelatedItemsTok);
    end;

    procedure AccruedSalariesWagesName(): Text[100]
    begin
        exit(AccruedSalariesWagesTok);
    end;

    procedure FederalIncomeTaxExpenseName(): Text[100]
    begin
        exit(FederalIncomeTaxExpenseTok);
    end;

    procedure ProvincialWithholdingPayableName(): Text[100]
    begin
        exit(ProvincialWithholdingPayableTok);
    end;

    procedure PayrollTaxesPayableName(): Text[100]
    begin
        exit(PayrollTaxesPayableTok);
    end;

    procedure FICAPayableName(): Text[100]
    begin
        exit(FICAPayableTok);
    end;

    procedure MedicarePayableName(): Text[100]
    begin
        exit(MedicarePayableTok);
    end;

    procedure FUTAPayableName(): Text[100]
    begin
        exit(FUTAPayableTok);
    end;

    procedure SUTAPayableName(): Text[100]
    begin
        exit(SUTAPayableTok);
    end;

    procedure EmployeeBenefitsPayableName(): Text[100]
    begin
        exit(EmployeeBenefitsPayableTok);
    end;

    procedure EmploymentInsuranceEmployeeContribName(): Text[100]
    begin
        exit(EmploymentInsuranceEmployeeContribTok);
    end;

    procedure EmploymentInsuranceEmployerContribName(): Text[100]
    begin
        exit(EmploymentInsuranceEmployerContribTok);
    end;

    procedure CanadaPensionFundEmployeeContribName(): Text[100]
    begin
        exit(CanadaPensionFundEmployeeContribTok);
    end;

    procedure CanadaPensionFundEmployerContribName(): Text[100]
    begin
        exit(CanadaPensionFundEmployerContribTok);
    end;

    procedure QuebecPIPPayableEmployeeName(): Text[100]
    begin
        exit(QuebecPIPPayableEmployeeTok);
    end;

    procedure GarnishmentPayableName(): Text[100]
    begin
        exit(GarnishmentPayableTok);
    end;

    procedure VacationCompensationPayableName(): Text[100]
    begin
        exit(VacationCompensationPayableTok);
    end;

    procedure EmployeesPayableName(): Text[100]
    begin
        exit(EmployeesPayableTok);
    end;

    procedure TotalPersonnelrelatedItemsName(): Text[100]
    begin
        exit(TotalPersonnelrelatedItemsTok);
    end;

    procedure OtherLiabilitiesName(): Text[100]
    begin
        exit(OtherLiabilitiesTok);
    end;

    procedure DividendsfortheFiscalYearName(): Text[100]
    begin
        exit(DividendsfortheFiscalYearTok);
    end;

    procedure CorporateTaxesPayableName(): Text[100]
    begin
        exit(CorporateTaxesPayableTok);
    end;

    procedure OtherLiabilitiesTotalName(): Text[100]
    begin
        exit(OtherLiabilitiesTotalTok);
    end;

    procedure ShorttermLiabilitiesTotalName(): Text[100]
    begin
        exit(ShorttermLiabilitiesTotalTok);
    end;

    procedure LongtermLiabilitiesName(): Text[100]
    begin
        exit(LongtermLiabilitiesTok);
    end;

    procedure LongtermBankLoansName(): Text[100]
    begin
        exit(LongtermBankLoansTok);
    end;

    procedure MortgageName(): Text[100]
    begin
        exit(MortgageTok);
    end;

    procedure DeferredTaxesName(): Text[100]
    begin
        exit(DeferredTaxesTok);
    end;

    procedure DeferralRevenueName(): Text[100]
    begin
        exit(DeferralRevenueTok);
    end;

    procedure LongtermLiabilitiesTotalName(): Text[100]
    begin
        exit(LongtermLiabilitiesTotalTok);
    end;

    procedure TotalLiabilitiesName(): Text[100]
    begin
        exit(TotalLiabilitiesTok);
    end;

    procedure EquityName(): Text[100]
    begin
        exit(EQUITYTok);
    end;

    procedure CapitalStockName(): Text[100]
    begin
        exit(CapitalStockTok);
    end;

    procedure RetainedEarningsName(): Text[100]
    begin
        exit(RetainedEarningsTok);
    end;

    procedure NetIncomefortheYearName(): Text[100]
    begin
        exit(NetIncomefortheYearTok);
    end;

    procedure TotalStockholdersEquityName(): Text[100]
    begin
        exit(TotalStockholdersEquityTok);
    end;

    procedure TOTALLIABILITIESANDEQUITYName(): Text[100]
    begin
        exit(TOTALLIABILITIESANDEQUITYTok);
    end;

    procedure IncomeStatementName(): Text[100]
    begin
        exit(INCOMESTATEMENTTok);
    end;

    procedure RevenueName(): Text[100]
    begin
        exit(RevenueTok);
    end;

    procedure SalesofJobsName(): Text[100]
    begin
        exit(SalesofJobsTok);
    end;

    procedure SalesOtherJobExpensesName(): Text[100]
    begin
        exit(SalesOtherJobExpensesTok);
    end;

    procedure JobSalesName(): Text[100]
    begin
        exit(JobSalesTok);
    end;

    procedure TotalSalesofJobsName(): Text[100]
    begin
        exit(TotalSalesofJobsTok);
    end;

    procedure SalesofServiceContractsName(): Text[100]
    begin
        exit(SalesofServiceContractsTok);
    end;

    procedure ServiceContractSaleName(): Text[100]
    begin
        exit(ServiceContractSaleTok);
    end;

    procedure TotalSaleofServContractsName(): Text[100]
    begin
        exit(TotalSaleofServContractsTok);
    end;

    procedure SalesofResourcesName(): Text[100]
    begin
        exit(SalesofResourcesTok);
    end;

    procedure SalesResourcesDomName(): Text[100]
    begin
        exit(SalesResourcesDomTok);
    end;

    procedure SalesResourcesExportName(): Text[100]
    begin
        exit(SalesResourcesExportTok);
    end;

    procedure JobSalesAdjmtResourcesName(): Text[100]
    begin
        exit(JobSalesAdjmtResourcesTok);
    end;

    procedure TotalSalesofResourcesName(): Text[100]
    begin
        exit(TotalSalesofResourcesTok);
    end;

    procedure SalesofRawMaterialsName(): Text[100]
    begin
        exit(SalesofRawMaterialsTok);
    end;

    procedure SalesRawMaterialsDomName(): Text[100]
    begin
        exit(SalesRawMaterialsDomTok);
    end;

    procedure SalesRawMaterialsExportName(): Text[100]
    begin
        exit(SalesRawMaterialsExportTok);
    end;

    procedure JobSalesAdjmtRawMatName(): Text[100]
    begin
        exit(JobSalesAdjmtRawMatTok);
    end;

    procedure TotalSalesofRawMaterialsName(): Text[100]
    begin
        exit(TotalSalesofRawMaterialsTok);
    end;

    procedure SalesofRetailName(): Text[100]
    begin
        exit(SalesofRetailTok);
    end;

    procedure SalesRetailDomName(): Text[100]
    begin
        exit(SalesRetailDomTok);
    end;

    procedure SalesRetailExportName(): Text[100]
    begin
        exit(SalesRetailExportTok);
    end;

    procedure JobSalesAppliedRetailName(): Text[100]
    begin
        exit(JobSalesAppliedRetailTok);
    end;

    procedure JobSalesAdjmtRetailName(): Text[100]
    begin
        exit(JobSalesAdjmtRetailTok);
    end;

    procedure TotalSalesofRetailName(): Text[100]
    begin
        exit(TotalSalesofRetailTok);
    end;

    procedure InterestIncomeName(): Text[100]
    begin
        exit(InterestIncomeTok);
    end;

    procedure InterestonBankBalancesName(): Text[100]
    begin
        exit(InterestonBankBalancesTok);
    end;

    procedure FinanceChargesfromCustomersName(): Text[100]
    begin
        exit(FinanceChargesfromCustomersTok);
    end;

    procedure PmtDiscReceivedDecreasesName(): Text[100]
    begin
        exit(PmtDiscReceivedDecreasesTok);
    end;

    procedure PaymentDiscountsReceivedName(): Text[100]
    begin
        exit(PaymentDiscountsReceivedTok);
    end;

    procedure InvoiceRoundingName(): Text[100]
    begin
        exit(InvoiceRoundingTok);
    end;

    procedure ApplicationRoundingName(): Text[100]
    begin
        exit(ApplicationRoundingTok);
    end;

    procedure PaymentToleranceReceivedName(): Text[100]
    begin
        exit(PaymentToleranceReceivedTok);
    end;

    procedure PmtTolReceivedDecreasesName(): Text[100]
    begin
        exit(PmtTolReceivedDecreasesTok);
    end;

    procedure ConsultingFeesDomName(): Text[100]
    begin
        exit(ConsultingFeesDomTok);
    end;

    procedure FeesandChargesRecDomName(): Text[100]
    begin
        exit(FeesandChargesRecDomTok);
    end;

    procedure DiscountGrantedName(): Text[100]
    begin
        exit(DiscountGrantedTok);
    end;

    procedure TotalInterestIncomeName(): Text[100]
    begin
        exit(TotalInterestIncomeTok);
    end;

    procedure TotalRevenueName(): Text[100]
    begin
        exit(TotalRevenueTok);
    end;

    procedure CostName(): Text[100]
    begin
        exit(CostTok);
    end;

    procedure JobCostsName(): Text[100]
    begin
        exit(JobCostsTok);
    end;

    procedure CostofResourcesName(): Text[100]
    begin
        exit(CostofResourcesTok);
    end;

    procedure CostofResourcesUsedName(): Text[100]
    begin
        exit(CostofResourcesUsedTok);
    end;

    procedure JobCostAdjmtResourcesName(): Text[100]
    begin
        exit(JobCostAdjmtResourcesTok);
    end;

    procedure JobCostAppliedResourcesName(): Text[100]
    begin
        exit(JobCostAppliedResourcesTok);
    end;

    procedure TotalCostofResourcesName(): Text[100]
    begin
        exit(TotalCostofResourcesTok);
    end;

    procedure CostofCapacitiesName(): Text[100]
    begin
        exit(CostofCapacitiesTok);
    end;

    procedure DirectCostAppliedCapName(): Text[100]
    begin
        exit(DirectCostAppliedCapTok);
    end;

    procedure OverheadAppliedCapName(): Text[100]
    begin
        exit(OverheadAppliedCapTok);
    end;

    procedure PurchaseVarianceCapName(): Text[100]
    begin
        exit(PurchaseVarianceCapTok);
    end;

    procedure TotalCostofCapacitiesName(): Text[100]
    begin
        exit(TotalCostofCapacitiesTok);
    end;

    procedure CostofRawMaterialsName(): Text[100]
    begin
        exit(CostofRawMaterialsTok);
    end;

    procedure PurchRawMaterialsDomName(): Text[100]
    begin
        exit(PurchRawMaterialsDomTok);
    end;

    procedure PurchRawMaterialsExportName(): Text[100]
    begin
        exit(PurchRawMaterialsExportTok);
    end;

    procedure DiscReceivedRawMaterialsName(): Text[100]
    begin
        exit(DiscReceivedRawMaterialsTok);
    end;

    procedure DeliveryExpensesRawMatName(): Text[100]
    begin
        exit(DeliveryExpensesRawMatTok);
    end;

    procedure InventoryAdjmtRawMatName(): Text[100]
    begin
        exit(InventoryAdjmtRawMatTok);
    end;

    procedure DeliveryExpensesRetailName(): Text[100]
    begin
        exit(DeliveryExpensesRetailTok);
    end;

    procedure JobCostAdjmtRawMaterialsName(): Text[100]
    begin
        exit(JobCostAdjmtRawMaterialsTok);
    end;

    procedure JobCostAppliedRawMaterialsName(): Text[100]
    begin
        exit(JobCostAppliedRawMaterialsTok);
    end;

    procedure CostofRawMaterialsSoldName(): Text[100]
    begin
        exit(CostofRawMaterialsSoldTok);
    end;

    procedure DirectCostAppliedRawmatName(): Text[100]
    begin
        exit(DirectCostAppliedRawmatTok);
    end;

    procedure OverheadAppliedRawmatName(): Text[100]
    begin
        exit(OverheadAppliedRawmatTok);
    end;

    procedure PurchaseVarianceRawmatName(): Text[100]
    begin
        exit(PurchaseVarianceRawmatTok);
    end;

    procedure TotalCostofRawMaterialsName(): Text[100]
    begin
        exit(TotalCostofRawMaterialsTok);
    end;

    procedure CostofRetailName(): Text[100]
    begin
        exit(CostofRetailTok);
    end;

    procedure PurchRetailDomName(): Text[100]
    begin
        exit(PurchRetailDomTok);
    end;

    procedure PurchRetailExportName(): Text[100]
    begin
        exit(PurchRetailExportTok);
    end;

    procedure DiscReceivedRetailName(): Text[100]
    begin
        exit(DiscReceivedRetailTok);
    end;

    procedure InventoryAdjmtRetailName(): Text[100]
    begin
        exit(InventoryAdjmtRetailTok);
    end;

    procedure JobCostAppliedRetailName(): Text[100]
    begin
        exit(JobCostAppliedRetailTok);
    end;

    procedure JobCostAdjmtRetailName(): Text[100]
    begin
        exit(JobCostAdjmtRetailTok);
    end;

    procedure CostofRetailSoldName(): Text[100]
    begin
        exit(CostofRetailSoldTok);
    end;

    procedure OverheadAppliedRetailName(): Text[100]
    begin
        exit(OverheadAppliedRetailTok);
    end;

    procedure PurchaseVarianceRetailName(): Text[100]
    begin
        exit(PurchaseVarianceRetailTok);
    end;

    procedure DirectCostAppliedRetailName(): Text[100]
    begin
        exit(DirectCostAppliedRetailTok);
    end;

    procedure PaymentDiscountsGrantedName(): Text[100]
    begin
        exit(PaymentDiscountsGrantedTok);
    end;

    procedure TotalCostofRetailName(): Text[100]
    begin
        exit(TotalCostofRetailTok);
    end;

    procedure VarianceName(): Text[100]
    begin
        exit(VarianceTok);
    end;

    procedure MaterialVarianceName(): Text[100]
    begin
        exit(MaterialVarianceTok);
    end;

    procedure CapacityVarianceName(): Text[100]
    begin
        exit(CapacityVarianceTok);
    end;

    procedure SubcontractedVarianceName(): Text[100]
    begin
        exit(SubcontractedVarianceTok);
    end;

    procedure CapOverheadVarianceName(): Text[100]
    begin
        exit(CapOverheadVarianceTok);
    end;

    procedure MfgOverheadVarianceName(): Text[100]
    begin
        exit(MfgOverheadVarianceTok);
    end;

    procedure TotalVarianceName(): Text[100]
    begin
        exit(TotalVarianceTok);
    end;

    procedure TotalCostName(): Text[100]
    begin
        exit(TotalCostTok);
    end;

    procedure OperatingExpensesName(): Text[100]
    begin
        exit(OperatingExpensesTok);
    end;

    procedure SellingExpensesName(): Text[100]
    begin
        exit(SellingExpensesTok);
    end;

    procedure AdvertisingName(): Text[100]
    begin
        exit(AdvertisingTok);
    end;

    procedure EntertainmentandPRName(): Text[100]
    begin
        exit(EntertainmentandPRTok);
    end;

    procedure TravelName(): Text[100]
    begin
        exit(TravelTok);
    end;

    procedure DeliveryExpensesName(): Text[100]
    begin
        exit(DeliveryExpensesTok);
    end;

    procedure TotalSellingExpensesName(): Text[100]
    begin
        exit(TotalSellingExpensesTok);
    end;

    procedure PersonnelExpensesName(): Text[100]
    begin
        exit(PersonnelExpensesTok);
    end;

    procedure WagesName(): Text[100]
    begin
        exit(WagesTok);
    end;

    procedure SalariesName(): Text[100]
    begin
        exit(SalariesTok);
    end;

    procedure RetirementPlanContributionsName(): Text[100]
    begin
        exit(RetirementPlanContributionsTok);
    end;

    procedure VacationCompensationName(): Text[100]
    begin
        exit(VacationCompensationTok);
    end;

    procedure PayrollTaxesName(): Text[100]
    begin
        exit(PayrollTaxesTok);
    end;

    procedure HealthInsuranceName(): Text[100]
    begin
        exit(HealthInsuranceTok);
    end;

    procedure GroupLifeInsuranceName(): Text[100]
    begin
        exit(GroupLifeInsuranceTok);
    end;

    procedure WorkersCompensationName(): Text[100]
    begin
        exit(WorkersCompensationTok);
    end;

    procedure KContributionsName(): Text[100]
    begin
        exit(KContributionsTok);
    end;

    procedure TotalPersonnelExpensesName(): Text[100]
    begin
        exit(TotalPersonnelExpensesTok);
    end;

    procedure VehicleExpensesName(): Text[100]
    begin
        exit(VehicleExpensesTok);
    end;

    procedure GasolineandMotorOilName(): Text[100]
    begin
        exit(GasolineandMotorOilTok);
    end;

    procedure RegistrationFeesName(): Text[100]
    begin
        exit(RegistrationFeesTok);
    end;

    procedure RepairsandMaintenanceName(): Text[100]
    begin
        exit(RepairsandMaintenanceTok);
    end;

    procedure TaxesName(): Text[100]
    begin
        exit(TaxesTok);
    end;

    procedure TotalVehicleExpensesName(): Text[100]
    begin
        exit(TotalVehicleExpensesTok);
    end;

    procedure ComputerExpensesName(): Text[100]
    begin
        exit(ComputerExpensesTok);
    end;

    procedure SoftwareName(): Text[100]
    begin
        exit(SoftwareTok);
    end;

    procedure ConsultantServicesName(): Text[100]
    begin
        exit(ConsultantServicesTok);
    end;

    procedure OtherComputerExpensesName(): Text[100]
    begin
        exit(OtherComputerExpensesTok);
    end;

    procedure TotalComputerExpensesName(): Text[100]
    begin
        exit(TotalComputerExpensesTok);
    end;

    procedure BuildingMaintenanceExpensesName(): Text[100]
    begin
        exit(BuildingMaintenanceExpensesTok);
    end;

    procedure CleaningName(): Text[100]
    begin
        exit(CleaningTok);
    end;

    procedure ElectricityandHeatingName(): Text[100]
    begin
        exit(ElectricityandHeatingTok);
    end;

    procedure TotalBldgMaintExpensesName(): Text[100]
    begin
        exit(TotalBldgMaintExpensesTok);
    end;

    procedure AdministrativeExpensesName(): Text[100]
    begin
        exit(AdministrativeExpensesTok);
    end;

    procedure OfficeSuppliesName(): Text[100]
    begin
        exit(OfficeSuppliesTok);
    end;

    procedure PhoneandFaxName(): Text[100]
    begin
        exit(PhoneandFaxTok);
    end;

    procedure PostageName(): Text[100]
    begin
        exit(PostageTok);
    end;

    procedure TotalAdministrativeExpensesName(): Text[100]
    begin
        exit(TotalAdministrativeExpensesTok);
    end;

    procedure OtherOperatingExpensesName(): Text[100]
    begin
        exit(OtherOperatingExpensesTok);
    end;

    procedure CashDiscrepanciesName(): Text[100]
    begin
        exit(CashDiscrepanciesTok);
    end;

    procedure BadDebtExpensesName(): Text[100]
    begin
        exit(BadDebtExpensesTok);
    end;

    procedure LegalandAccountingServicesName(): Text[100]
    begin
        exit(LegalandAccountingServicesTok);
    end;

    procedure MiscellaneousName(): Text[100]
    begin
        exit(MiscellaneousTok);
    end;

    procedure OtherCostsofOperationsName(): Text[100]
    begin
        exit(OtherCostsofOperationsTok);
    end;

    procedure OtherOperatingExpTotalName(): Text[100]
    begin
        exit(OtherOperatingExpTotalTok);
    end;

    procedure TotalOperatingExpensesName(): Text[100]
    begin
        exit(TotalOperatingExpensesTok);
    end;

    procedure EBITDAName(): Text[100]
    begin
        exit(EBITDATok);
    end;

    procedure DepreciationofFixedAssetsName(): Text[100]
    begin
        exit(DepreciationofFixedAssetsTok);
    end;

    procedure DepreciationBuildingsName(): Text[100]
    begin
        exit(DepreciationBuildingsTok);
    end;

    procedure DepreciationEquipmentName(): Text[100]
    begin
        exit(DepreciationEquipmentTok);
    end;

    procedure DepreciationVehiclesName(): Text[100]
    begin
        exit(DepreciationVehiclesTok);
    end;

    procedure TotalFixedAssetDepreciationName(): Text[100]
    begin
        exit(TotalFixedAssetDepreciationTok);
    end;

    procedure InterestExpensesName(): Text[100]
    begin
        exit(InterestExpensesTok);
    end;

    procedure InterestonRevolvingCreditName(): Text[100]
    begin
        exit(InterestonRevolvingCreditTok);
    end;

    procedure InterestonBankLoansName(): Text[100]
    begin
        exit(InterestonBankLoansTok);
    end;

    procedure MortgageInterestName(): Text[100]
    begin
        exit(MortgageInterestTok);
    end;

    procedure FinanceChargestoVendorsName(): Text[100]
    begin
        exit(FinanceChargestoVendorsTok);
    end;

    procedure PmtDiscGrantedDecreasesName(): Text[100]
    begin
        exit(PmtDiscGrantedDecreasesTok);
    end;

    procedure PaymentToleranceGrantedName(): Text[100]
    begin
        exit(PaymentToleranceGrantedTok);
    end;

    procedure PmtTolGrantedDecreasesName(): Text[100]
    begin
        exit(PmtTolGrantedDecreasesTok);
    end;

    procedure TotalInterestExpensesName(): Text[100]
    begin
        exit(TotalInterestExpensesTok);
    end;

    procedure GainsAndLossesName(): Text[100]
    begin
        exit(GAINSANDLOSSESTok);
    end;

    procedure UnrealizedFXGainsName(): Text[100]
    begin
        exit(UnrealizedFXGainsTok);
    end;

    procedure UnrealizedFXLossesName(): Text[100]
    begin
        exit(UnrealizedFXLossesTok);
    end;

    procedure RealizedFXGainsName(): Text[100]
    begin
        exit(RealizedFXGainsTok);
    end;

    procedure RealizedFXLossesName(): Text[100]
    begin
        exit(RealizedFXLossesTok);
    end;

    procedure TotalGainsAndLossesName(): Text[100]
    begin
        exit(TOTALGAINSANDLOSSESTok);
    end;

    procedure NetOperatingIncomeBeforeExtraOrdItemsTaxesName(): Text[100]
    begin
        exit(NetOperatingIncomeOrdItemsTaxesTok);
    end;

    procedure IncomeTaxesName(): Text[100]
    begin
        exit(IncomeTaxesTok);
    end;

    procedure CorporateTaxName(): Text[100]
    begin
        exit(CorporateTaxTok);
    end;

    procedure StateIncomeTaxName(): Text[100]
    begin
        exit(StateIncomeTaxTok);
    end;

    procedure TotalIncomeTaxesName(): Text[100]
    begin
        exit(TotalIncomeTaxesTok);
    end;

    procedure NetIncomeBeforeExtrItemsName(): Text[100]
    begin
        exit(NETINCOMEBEFOREEXTRITEMSTok);
    end;

    procedure ExtraordinaryItemsName(): Text[100]
    begin
        exit(ExtraordinaryItemsTok);
    end;

    procedure ExtraordinaryIncomeName(): Text[100]
    begin
        exit(ExtraordinaryIncomeTok);
    end;

    procedure RevaluationSurplusadjustmentsName(): Text[100]
    begin
        exit(RevaluationSurplusadjustmentsTok);
    end;

    procedure ExtraordinaryExpensesName(): Text[100]
    begin
        exit(ExtraordinaryExpensesTok);
    end;

    procedure ExtraordinaryItemsTotalName(): Text[100]
    begin
        exit(ExtraordinaryItemsTotalTok);
    end;

    var
        ASSETSTok: Label 'ASSETS', MaxLength = 100;
        CurrentAssetsTok: Label 'Current Assets', MaxLength = 100;
        LiquidAssetsTok: Label 'Liquid Assets', MaxLength = 100;
        CashTok: Label 'Cash', MaxLength = 100;
        BankCheckingTok: Label 'Bank, Checking', MaxLength = 100;
        BankCurrenciesLCYTok: Label 'Bank Currencies LCY', MaxLength = 100;
        BankCurrenciesFCYUSDTok: Label 'Bank Currencies FCY - USD ', MaxLength = 100;
        BankOperationsCashTok: Label 'Bank Operations Cash', MaxLength = 100;
        LiquidAssetsTotalTok: Label 'Liquid Assets, Total', MaxLength = 100;
        SecuritiesTok: Label 'Securities', MaxLength = 100;
        ShortTermInvestmentsTok: Label 'Short Term Investments', MaxLength = 100;
        CanadianTermDepositsTok: Label 'Canadian Term Deposits', MaxLength = 100;
        BondsTok: Label 'Bonds', MaxLength = 100;
        OtherMarketableSecuritiesTok: Label 'Other Marketable Securities', MaxLength = 100;
        InterestAccruedoninvestmentTok: Label 'Interest Accrued on investment', MaxLength = 100;
        SecuritiesTotalTok: Label 'Securities, Total', MaxLength = 100;
        AccountsReceivableTok: Label 'Accounts Receivable', MaxLength = 100;
        CustomersDomesticCADTok: Label 'Customers Domestic/CAD', MaxLength = 100;
        CustomersForeignFCYTok: Label 'Customers, Foreign/FCY', MaxLength = 100;
        OtherReceivablesTok: Label 'Other Receivables ', MaxLength = 100;
        AccountsReceivableTotalTok: Label 'Accounts Receivable, Total', MaxLength = 100;
        PurchasePrepaymentsTok: Label 'Purchase Prepayments', MaxLength = 100;
        VendorPrepaymentsSERVICESTok: Label 'Vendor Prepayments SERVICES', MaxLength = 100;
        VendorPrepaymentsRETAILTok: Label 'Vendor Prepayments RETAIL', MaxLength = 100;
        PurchasePrepaymentsTotalTok: Label 'Purchase Prepayments, Total', MaxLength = 100;
        InventoryTok: Label 'Inventory', MaxLength = 100;
        ResaleItemsTok: Label 'Resale Items', MaxLength = 100;
        ResaleItemsInterimTok: Label 'Resale Items (Interim)', MaxLength = 100;
        CostofResaleSoldInterimTok: Label 'Cost of Resale Sold (Interim)', MaxLength = 100;
        FinishedGoodsTok: Label 'Finished Goods', MaxLength = 100;
        FinishedGoodsInterimTok: Label 'Finished Goods (Interim)', MaxLength = 100;
        RawMaterialsTok: Label 'Raw Materials', MaxLength = 100;
        RawMaterialsInterimTok: Label 'Raw Materials (Interim)', MaxLength = 100;
        CostofRawMatSoldInterimTok: Label 'Cost of Raw Mat.Sold (Interim)', MaxLength = 100;
        PrimoInventoryTok: Label 'Primo Inventory', MaxLength = 100;
        AllowanceforFinishedGoodsWriteOffsTok: Label 'Allowance for Finished Goods Write-Offs', MaxLength = 100;
        WIPAccountFinishedgoodsTok: Label 'WIP Account, Finished goods', MaxLength = 100;
        InventoryTotalTok: Label 'Inventory, Total', MaxLength = 100;
        JobWIPTok: Label 'Job WIP', MaxLength = 100;
        WIPSalesTok: Label 'WIP Sales', MaxLength = 100;
        WIPJobSalesTok: Label 'WIP Job Sales', MaxLength = 100;
        InvoicedJobSalesTok: Label 'Invoiced Job Sales', MaxLength = 100;
        WIPSalesTotalTok: Label 'WIP Sales, Total', MaxLength = 100;
        WIPCostsTok: Label 'WIP Costs', MaxLength = 100;
        WIPJobCostsTok: Label 'WIP Job Costs', MaxLength = 100;
        AccruedJobCostsTok: Label 'Accrued Job Costs', MaxLength = 100;
        WIPCostsTotalTok: Label 'WIP Costs, Total', MaxLength = 100;
        JobWIPTotalTok: Label 'Job WIP, Total', MaxLength = 100;
        CurrentAssetsTotalTok: Label 'Current Assets, Total', MaxLength = 100;
        FixedAssetsTok: Label 'Fixed Assets', MaxLength = 100;
        TangibleFixedAssetsTok: Label 'Tangible Fixed Assets', MaxLength = 100;
        VehiclesTok: Label 'Vehicles', MaxLength = 100;
        AccumDepreciationVehiclesTok: Label 'Accum. Depreciation, Vehicles', MaxLength = 100;
        VehiclesTotalTok: Label 'Vehicles, Total', MaxLength = 100;
        OperatingEquipmentTok: Label 'Operating Equipment', MaxLength = 100;
        AccumDeprOperEquipTok: Label 'Accum. Depr., Oper. Equip.', MaxLength = 100;
        OperatingEquipmentTotalTok: Label 'Operating Equipment, Total', MaxLength = 100;
        LandandBuildingsTok: Label 'Land and Buildings', MaxLength = 100;
        AccumDepreciationBuildingsTok: Label 'Accum. Depreciation, Buildings', MaxLength = 100;
        LandandBuildingsTotalTok: Label 'Land and Buildings, Total', MaxLength = 100;
        TangibleFixedAssetsTotalTok: Label 'Tangible Fixed Assets, Total', MaxLength = 100;
        IntangibleAssetsTok: Label 'Intangible Assets', MaxLength = 100;
        AccAmortnonIntangiblesTok: Label 'Acc. Amortn on Intangibles', MaxLength = 100;
        IntangibleAssetsTotalTok: Label 'Intangible Assets, Total', MaxLength = 100;
        FixedAssetsTotalTok: Label 'Fixed Assets, Total', MaxLength = 100;
        TOTALASSETSTok: Label 'TOTAL ASSETS', MaxLength = 100;
        LIABILITIESANDEQUITYTok: Label 'LIABILITIES AND EQUITY', MaxLength = 100;
        LiabilitiesTok: Label 'Liabilities', MaxLength = 100;
        ShorttermLiabilitiesTok: Label 'Short-term Liabilities', MaxLength = 100;
        RevolvingCreditTok: Label 'Revolving Credit', MaxLength = 100;
        DeferredRevenueTok: Label 'Deferred Revenue', MaxLength = 100;
        SalesPrepaymentsTok: Label 'Sales Prepayments', MaxLength = 100;
        CustomerPrepaymentsSERVICESTok: Label 'Customer Prepayments SERVICES', MaxLength = 100;
        CustomerPrepaymentsRETAILTok: Label 'Customer Prepayments RETAIL', MaxLength = 100;
        SalesPrepaymentsTotalTok: Label 'Sales Prepayments, Total', MaxLength = 100;
        AccountsPayableTok: Label 'Accounts Payable', MaxLength = 100;
        VendorsDomesticTok: Label 'Vendors, Domestic', MaxLength = 100;
        VendorsForeignTok: Label 'Vendors, Foreign', MaxLength = 100;
        AccountsPayableEmployeesTok: Label 'Accounts Payable - Employees', MaxLength = 100;
        AccruedPayablesTok: Label 'Accrued Payables', MaxLength = 100;
        AccountsPayableTotalTok: Label 'Accounts Payable, Total', MaxLength = 100;
        InvAdjmtInterimTok: Label 'Inv. Adjmt. (Interim)', MaxLength = 100;
        InvAdjmtInterimRawMatTok: Label 'Inv. Adjmt. (Interim), Raw Mat', MaxLength = 100;
        InvAdjmtInterimRetailTok: Label 'Inv. Adjmt. (Interim), Retail', MaxLength = 100;
        InvAdjmtInterimTotalTok: Label 'Inv. Adjmt. (Interim), Total', MaxLength = 100;
        TaxesPayablesTok: Label 'Taxes Payables', MaxLength = 100;
        IncomeTaxPayableTok: Label 'Income Tax Payable ', MaxLength = 100;
        ProvincialSalesTaxTok: Label 'Provincial Sales Tax', MaxLength = 100;
        QSTSalesTaxCollectedTok: Label 'QST - Sales Tax Collected', MaxLength = 100;
        PurchaseTaxTok: Label 'Purchase Tax', MaxLength = 100;
        GSTHSTSalesTaxTok: Label 'GST/HST - Sales Tax', MaxLength = 100;
        GSTHSTInputCreditsTok: Label 'GST/HST -Input Credits', MaxLength = 100;
        IncomeTaxAccruedTok: Label 'Income Tax Accrued ', MaxLength = 100;
        QuebecBeerTaxesAccruedTok: Label 'Quebec Beer Taxes Accrued', MaxLength = 100;
        TaxesPayablesTotalTok: Label 'Taxes Payables, Total', MaxLength = 100;
        PrepaidServiceContractsTok: Label 'Prepaid Service Contracts', MaxLength = 100;
        PrepaidHardwareContractsTok: Label 'Prepaid Hardware Contracts', MaxLength = 100;
        PrepaidSoftwareContractsTok: Label 'Prepaid Software Contracts', MaxLength = 100;
        TotalPrepaidServiceContractTok: Label 'Total Prepaid Service Contract', MaxLength = 100;
        PersonnelrelatedItemsTok: Label 'Personnel-related Items', MaxLength = 100;
        AccruedSalariesWagesTok: Label 'Accrued Salaries & Wages', MaxLength = 100;
        FederalIncomeTaxExpenseTok: Label 'Federal Income Tax Expense', MaxLength = 100;
        ProvincialWithholdingPayableTok: Label 'Provincial Withholding Payable', MaxLength = 100;
        PayrollTaxesPayableTok: Label 'Payroll Taxes Payable', MaxLength = 100;
        FICAPayableTok: Label 'FICA Payable', MaxLength = 100;
        MedicarePayableTok: Label 'Medicare Payable', MaxLength = 100;
        FUTAPayableTok: Label 'FUTA Payable', MaxLength = 100;
        SUTAPayableTok: Label 'SUTA Payable', MaxLength = 100;
        EmployeeBenefitsPayableTok: Label 'Employee Benefits Payable', MaxLength = 100;
        EmploymentInsuranceEmployeeContribTok: Label 'Employment Insurance - Employee Contrib', MaxLength = 100;
        EmploymentInsuranceEmployerContribTok: Label 'Employment Insurance - Employer Contrib', MaxLength = 100;
        CanadaPensionFundEmployeeContribTok: Label 'Canada Pension Fund - Employee Contrib', MaxLength = 100;
        CanadaPensionFundEmployerContribTok: Label 'Canada Pension Fund - Employer Contrib', MaxLength = 100;
        QuebecPIPPayableEmployeeTok: Label 'Quebec PIP Payable - Employee ', MaxLength = 100;
        GarnishmentPayableTok: Label 'Garnishment Payable', MaxLength = 100;
        VacationCompensationPayableTok: Label 'Vacation Compensation Payable', MaxLength = 100;
        EmployeesPayableTok: Label 'Employees Payable', MaxLength = 100;
        TotalPersonnelrelatedItemsTok: Label 'Total Personnel-related Items', MaxLength = 100;
        OtherLiabilitiesTok: Label 'Other Liabilities', MaxLength = 100;
        DividendsfortheFiscalYearTok: Label 'Dividends for the Fiscal Year', MaxLength = 100;
        CorporateTaxesPayableTok: Label 'Corporate Taxes Payable', MaxLength = 100;
        OtherLiabilitiesTotalTok: Label 'Other Liabilities, Total', MaxLength = 100;
        ShorttermLiabilitiesTotalTok: Label 'Short-term Liabilities, Total', MaxLength = 100;
        LongtermLiabilitiesTok: Label 'Long-term Liabilities', MaxLength = 100;
        LongtermBankLoansTok: Label 'Long-term Bank Loans', MaxLength = 100;
        MortgageTok: Label 'Mortgage', MaxLength = 100;
        DeferredTaxesTok: Label 'Deferred Taxes', MaxLength = 100;
        DeferralRevenueTok: Label 'Deferral Revenue', MaxLength = 100;
        LongtermLiabilitiesTotalTok: Label 'Long-term Liabilities, Total', MaxLength = 100;
        TotalLiabilitiesTok: Label 'Total Liabilities', MaxLength = 100;
        EQUITYTok: Label 'EQUITY', MaxLength = 100;
        CapitalStockTok: Label 'Capital Stock', MaxLength = 100;
        RetainedEarningsTok: Label 'Retained Earnings', MaxLength = 100;
        NetIncomefortheYearTok: Label 'Net Income for the Year', MaxLength = 100;
        TotalStockholdersEquityTok: Label 'Total Stockholder''s Equity', MaxLength = 100;
        TOTALLIABILITIESANDEQUITYTok: Label 'TOTAL LIABILITIES AND EQUITY', MaxLength = 100;
        INCOMESTATEMENTTok: Label 'INCOME STATEMENT', MaxLength = 100;
        RevenueTok: Label 'Revenue', MaxLength = 100;
        SalesofJobsTok: Label 'Sales of Jobs', MaxLength = 100;
        SalesOtherJobExpensesTok: Label 'Sales, Other Job Expenses', MaxLength = 100;
        JobSalesTok: Label 'Job Sales', MaxLength = 100;
        TotalSalesofJobsTok: Label 'Total Sales of Jobs', MaxLength = 100;
        SalesofServiceContractsTok: Label 'Sales of Service Contracts', MaxLength = 100;
        ServiceContractSaleTok: Label 'Service Contract Sale', MaxLength = 100;
        TotalSaleofServContractsTok: Label 'Total Sale of Serv. Contracts', MaxLength = 100;
        SalesofResourcesTok: Label 'Sales of Resources', MaxLength = 100;
        SalesResourcesDomTok: Label 'Sales, Resources - Dom.', MaxLength = 100;
        SalesResourcesExportTok: Label 'Sales, Resources - Export', MaxLength = 100;
        JobSalesAdjmtResourcesTok: Label 'Job Sales Adjmt., Resources', MaxLength = 100;
        TotalSalesofResourcesTok: Label 'Total Sales of Resources', MaxLength = 100;
        SalesofRawMaterialsTok: Label 'Sales of Raw Materials', MaxLength = 100;
        SalesRawMaterialsDomTok: Label 'Sales, Raw Materials - Dom.', MaxLength = 100;
        SalesRawMaterialsExportTok: Label 'Sales, Raw Materials - Export', MaxLength = 100;
        JobSalesAdjmtRawMatTok: Label 'Job Sales Adjmt., Raw Mat.', MaxLength = 100;
        TotalSalesofRawMaterialsTok: Label 'Total Sales of Raw Materials', MaxLength = 100;
        SalesofRetailTok: Label 'Sales of Retail', MaxLength = 100;
        SalesRetailDomTok: Label 'Sales, Retail - Dom.', MaxLength = 100;
        SalesRetailExportTok: Label 'Sales, Retail - Export', MaxLength = 100;
        JobSalesAppliedRetailTok: Label 'Job Sales Applied, Retail', MaxLength = 100;
        JobSalesAdjmtRetailTok: Label 'Job Sales Adjmt., Retail', MaxLength = 100;
        TotalSalesofRetailTok: Label 'Total Sales of Retail', MaxLength = 100;
        InterestIncomeTok: Label 'Interest Income', MaxLength = 100;
        InterestonBankBalancesTok: Label 'Interest on Bank Balances', MaxLength = 100;
        FinanceChargesfromCustomersTok: Label 'Finance Charges from Customers', MaxLength = 100;
        PmtDiscReceivedDecreasesTok: Label 'PmtDisc. Received - Decreases', MaxLength = 100;
        PaymentDiscountsReceivedTok: Label 'Payment Discounts Received', MaxLength = 100;
        InvoiceRoundingTok: Label 'Invoice Rounding', MaxLength = 100;
        ApplicationRoundingTok: Label 'Application Rounding', MaxLength = 100;
        PaymentToleranceReceivedTok: Label 'Payment Tolerance Received', MaxLength = 100;
        PmtTolReceivedDecreasesTok: Label 'Pmt. Tol. Received Decreases', MaxLength = 100;
        ConsultingFeesDomTok: Label 'Consulting Fees - Dom.', MaxLength = 100;
        FeesandChargesRecDomTok: Label 'Fees and Charges Rec. - Dom.', MaxLength = 100;
        DiscountGrantedTok: Label 'Discount Granted', MaxLength = 100;
        TotalInterestIncomeTok: Label 'Total Interest Income', MaxLength = 100;
        TotalRevenueTok: Label 'Total Revenue', MaxLength = 100;
        CostTok: Label 'Cost', MaxLength = 100;
        JobCostsTok: Label 'Job Costs', MaxLength = 100;
        CostofResourcesTok: Label 'Cost of Resources', MaxLength = 100;
        CostofResourcesUsedTok: Label 'Cost of Resources Used', MaxLength = 100;
        JobCostAdjmtResourcesTok: Label 'Job Cost Adjmt., Resources', MaxLength = 100;
        JobCostAppliedResourcesTok: Label 'Job Cost Applied, Resources', MaxLength = 100;
        TotalCostofResourcesTok: Label 'Total Cost of Resources', MaxLength = 100;
        CostofCapacitiesTok: Label 'Cost of Capacities', MaxLength = 100;
        DirectCostAppliedCapTok: Label 'Direct Cost Applied, Cap.', MaxLength = 100;
        OverheadAppliedCapTok: Label 'Overhead Applied, Cap.', MaxLength = 100;
        PurchaseVarianceCapTok: Label 'Purchase Variance, Cap.', MaxLength = 100;
        TotalCostofCapacitiesTok: Label 'Total Cost of Capacities', MaxLength = 100;
        CostofRawMaterialsTok: Label 'Cost of Raw Materials', MaxLength = 100;
        PurchRawMaterialsDomTok: Label 'Purch., Raw Materials - Dom.', MaxLength = 100;
        PurchRawMaterialsExportTok: Label 'Purch., Raw Materials - Export', MaxLength = 100;
        DiscReceivedRawMaterialsTok: Label 'Disc. Received, Raw Materials', MaxLength = 100;
        DeliveryExpensesRawMatTok: Label 'Delivery Expenses, Raw Mat.', MaxLength = 100;
        InventoryAdjmtRawMatTok: Label 'Inventory Adjmt., Raw Mat.', MaxLength = 100;
        DeliveryExpensesRetailTok: Label 'Delivery Expenses, Retail', MaxLength = 100;
        JobCostAdjmtRawMaterialsTok: Label 'Job Cost Adjmt., Raw Materials', MaxLength = 100;
        JobCostAppliedRawMaterialsTok: Label 'Job Cost Applied, Raw Materials', MaxLength = 100;
        CostofRawMaterialsSoldTok: Label 'Cost of Raw Materials Sold', MaxLength = 100;
        DirectCostAppliedRawmatTok: Label 'Direct Cost Applied, Rawmat.', MaxLength = 100;
        OverheadAppliedRawmatTok: Label 'Overhead Applied, Rawmat.', MaxLength = 100;
        PurchaseVarianceRawmatTok: Label 'Purchase Variance, Rawmat.', MaxLength = 100;
        TotalCostofRawMaterialsTok: Label 'Total Cost of Raw Materials', MaxLength = 100;
        CostofRetailTok: Label 'Cost of Retail', MaxLength = 100;
        PurchRetailDomTok: Label 'Purch., Retail - Dom.', MaxLength = 100;
        PurchRetailExportTok: Label 'Purch., Retail - Export', MaxLength = 100;
        DiscReceivedRetailTok: Label 'Disc. Received, Retail', MaxLength = 100;
        InventoryAdjmtRetailTok: Label 'Inventory Adjmt., Retail', MaxLength = 100;
        JobCostAppliedRetailTok: Label 'Job Cost Applied, Retail', MaxLength = 100;
        JobCostAdjmtRetailTok: Label 'Job Cost Adjmt., Retail', MaxLength = 100;
        CostofRetailSoldTok: Label 'Cost of Retail Sold', MaxLength = 100;
        OverheadAppliedRetailTok: Label 'Overhead Applied, Retail', MaxLength = 100;
        PurchaseVarianceRetailTok: Label 'Purchase Variance, Retail', MaxLength = 100;
        DirectCostAppliedRetailTok: Label 'Direct Cost Applied, Retail', MaxLength = 100;
        PaymentDiscountsGrantedTok: Label 'Payment Discounts Granted', MaxLength = 100;
        TotalCostofRetailTok: Label 'Total Cost of Retail', MaxLength = 100;
        VarianceTok: Label 'Variance', MaxLength = 100;
        MaterialVarianceTok: Label 'Material Variance', MaxLength = 100;
        CapacityVarianceTok: Label 'Capacity Variance', MaxLength = 100;
        SubcontractedVarianceTok: Label 'Subcontracted Variance', MaxLength = 100;
        CapOverheadVarianceTok: Label 'Cap. Overhead Variance', MaxLength = 100;
        MfgOverheadVarianceTok: Label 'Mfg. Overhead Variance', MaxLength = 100;
        TotalVarianceTok: Label 'Total Variance', MaxLength = 100;
        TotalCostTok: Label 'Total Cost', MaxLength = 100;
        OperatingExpensesTok: Label 'Operating Expenses', MaxLength = 100;
        SellingExpensesTok: Label 'Selling Expenses', MaxLength = 100;
        AdvertisingTok: Label 'Advertising', MaxLength = 100;
        EntertainmentandPRTok: Label 'Entertainment and PR', MaxLength = 100;
        TravelTok: Label 'Travel', MaxLength = 100;
        DeliveryExpensesTok: Label 'Delivery Expenses', MaxLength = 100;
        TotalSellingExpensesTok: Label 'Total Selling Expenses', MaxLength = 100;
        PersonnelExpensesTok: Label 'Personnel Expenses', MaxLength = 100;
        WagesTok: Label 'Wages', MaxLength = 100;
        SalariesTok: Label 'Salaries', MaxLength = 100;
        RetirementPlanContributionsTok: Label 'Retirement Plan Contributions', MaxLength = 100;
        VacationCompensationTok: Label 'Vacation Compensation', MaxLength = 100;
        PayrollTaxesTok: Label 'Payroll Taxes', MaxLength = 100;
        HealthInsuranceTok: Label 'Health Insurance', MaxLength = 100;
        GroupLifeInsuranceTok: Label 'Group Life Insurance', MaxLength = 100;
        WorkersCompensationTok: Label 'Workers Compensation', MaxLength = 100;
        KContributionsTok: Label '401K Contributions', MaxLength = 100;
        TotalPersonnelExpensesTok: Label 'Total Personnel Expenses', MaxLength = 100;
        VehicleExpensesTok: Label 'Vehicle Expenses', MaxLength = 100;
        GasolineandMotorOilTok: Label 'Gasoline and Motor Oil', MaxLength = 100;
        RegistrationFeesTok: Label 'Registration Fees', MaxLength = 100;
        RepairsandMaintenanceTok: Label 'Repairs and Maintenance', MaxLength = 100;
        TaxesTok: Label 'Taxes', MaxLength = 100;
        TotalVehicleExpensesTok: Label 'Total Vehicle Expenses', MaxLength = 100;
        ComputerExpensesTok: Label 'Computer Expenses', MaxLength = 100;
        SoftwareTok: Label 'Software', MaxLength = 100;
        ConsultantServicesTok: Label 'Consultant Services', MaxLength = 100;
        OtherComputerExpensesTok: Label 'Other Computer Expenses', MaxLength = 100;
        TotalComputerExpensesTok: Label 'Total Computer Expenses', MaxLength = 100;
        BuildingMaintenanceExpensesTok: Label 'Building Maintenance Expenses', MaxLength = 100;
        CleaningTok: Label 'Cleaning', MaxLength = 100;
        ElectricityandHeatingTok: Label 'Electricity and Heating', MaxLength = 100;
        TotalBldgMaintExpensesTok: Label 'Total Bldg. Maint. Expenses', MaxLength = 100;
        AdministrativeExpensesTok: Label 'Administrative Expenses', MaxLength = 100;
        OfficeSuppliesTok: Label 'Office Supplies', MaxLength = 100;
        PhoneandFaxTok: Label 'Phone and Fax', MaxLength = 100;
        PostageTok: Label 'Postage', MaxLength = 100;
        TotalAdministrativeExpensesTok: Label 'Total Administrative Expenses', MaxLength = 100;
        OtherOperatingExpensesTok: Label 'Other Operating Expenses', MaxLength = 100;
        CashDiscrepanciesTok: Label 'Cash Discrepancies', MaxLength = 100;
        BadDebtExpensesTok: Label 'Bad Debt Expenses', MaxLength = 100;
        LegalandAccountingServicesTok: Label 'Legal and Accounting Services', MaxLength = 100;
        MiscellaneousTok: Label 'Miscellaneous', MaxLength = 100;
        OtherCostsofOperationsTok: Label 'Other Costs of Operations', MaxLength = 100;
        OtherOperatingExpTotalTok: Label 'Other Operating Exp., Total', MaxLength = 100;
        TotalOperatingExpensesTok: Label 'Total Operating Expenses', MaxLength = 100;
        EBITDATok: Label 'EBITDA', MaxLength = 100;
        DepreciationofFixedAssetsTok: Label 'Depreciation of Fixed Assets', MaxLength = 100;
        DepreciationBuildingsTok: Label 'Depreciation, Buildings', MaxLength = 100;
        DepreciationEquipmentTok: Label 'Depreciation, Equipment', MaxLength = 100;
        DepreciationVehiclesTok: Label 'Depreciation, Vehicles', MaxLength = 100;
        TotalFixedAssetDepreciationTok: Label 'Total Fixed Asset Depreciation', MaxLength = 100;
        InterestExpensesTok: Label 'Interest Expenses', MaxLength = 100;
        InterestonRevolvingCreditTok: Label 'Interest on Revolving Credit', MaxLength = 100;
        InterestonBankLoansTok: Label 'Interest on Bank Loans', MaxLength = 100;
        MortgageInterestTok: Label 'Mortgage Interest', MaxLength = 100;
        FinanceChargestoVendorsTok: Label 'Finance Charges to Vendors', MaxLength = 100;
        PmtDiscGrantedDecreasesTok: Label 'PmtDisc. Granted - Decreases', MaxLength = 100;
        PaymentToleranceGrantedTok: Label 'Payment Tolerance Granted', MaxLength = 100;
        PmtTolGrantedDecreasesTok: Label 'Pmt. Tol. Granted Decreases', MaxLength = 100;
        TotalInterestExpensesTok: Label 'Total Interest Expenses', MaxLength = 100;
        GAINSANDLOSSESTok: Label 'GAINS AND LOSSES', MaxLength = 100;
        UnrealizedFXGainsTok: Label 'Unrealized FX Gains', MaxLength = 100;
        UnrealizedFXLossesTok: Label 'Unrealized FX Losses', MaxLength = 100;
        RealizedFXGainsTok: Label 'Realized FX Gains', MaxLength = 100;
        RealizedFXLossesTok: Label 'Realized FX Losses', MaxLength = 100;
        TOTALGAINSANDLOSSESTok: Label 'TOTAL GAINS AND LOSSES', MaxLength = 100;
        NetOperatingIncomeOrdItemsTaxesTok: Label 'NI BEFORE EXTR. ITEMS & TAXES', MaxLength = 100;
        IncomeTaxesTok: Label 'Income Taxes', MaxLength = 100;
        CorporateTaxTok: Label 'Corporate Tax', MaxLength = 100;
        StateIncomeTaxTok: Label 'State Income Tax', MaxLength = 100;
        TotalIncomeTaxesTok: Label 'Total Income Taxes', MaxLength = 100;
        NETINCOMEBEFOREEXTRITEMSTok: Label 'NET INCOME BEFORE EXTR. ITEMS', MaxLength = 100;
        ExtraordinaryItemsTok: Label 'Extraordinary Items', MaxLength = 100;
        ExtraordinaryIncomeTok: Label 'Extraordinary Income', MaxLength = 100;
        RevaluationSurplusadjustmentsTok: Label 'Revaluation Surplus adjustments ', MaxLength = 100;
        ExtraordinaryExpensesTok: Label 'Extraordinary Expenses', MaxLength = 100;
        ExtraordinaryItemsTotalTok: Label 'Extraordinary Items, Total', MaxLength = 100;

}