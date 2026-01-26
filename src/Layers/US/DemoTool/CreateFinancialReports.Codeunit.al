codeunit 119101 "Create Financial Reports"
{

    trigger OnRun()
    begin
        // Balance Sheet
        UpdateTotalling('M-BALANCE', 'P0003', CreateGLAccount.BusinessaccountOperatingDomestic() + '..' + CreateGLAccount.PettyCash(), false); // Cash
        UpdateTotalling('M-BALANCE', 'P0004', CreateGLAccount.AccountReceivableDomestic(), false); // Account  Receivables
        UpdateTotalling('M-BALANCE', 'P0005', CreateGLAccount.PrepaidRent() + '..' + CreateGLAccount.Otherprepaidexpensesandaccruedincome(), false); // Prepaid Expences
        UpdateTotalling('M-BALANCE', 'P0006', CreateGLAccount.FinishedGoods(), false); // Inventory
        UpdateTotalling('M-BALANCE', 'P0009', CreateGLAccount.EquipmentsandTools(), false); // Equipment
        UpdateTotalling('M-BALANCE', 'P0010', CreateGLAccount.AccumulatedDepreciation(), false); // Accumulated Depreciation
        UpdateTotalling('M-BALANCE', 'P0016', CreateGLAccount.AccountsPayableDomestic() + '..' + CreateGLAccount.SalesTax_VATLiable(), false); // Current Liabilities
        UpdateTotalling('M-BALANCE', 'P0016', CreateGLAccount.TaxesLiable() + '..' + CreateGLAccount.OtherSalary_wageDeductions(), false); // Payroll Liabilities
        UpdateTotalling('M-BALANCE', 'P0018', CreateGLAccount.OtherLiabilities(), false); // Long Term Liabilities
        UpdateTotalling('M-BALANCE', 'P0022', CreateGLAccount.Non_RestrictedEquity(), false); // Common Stock
        UpdateTotalling('M-BALANCE', 'P0023', CreateGLAccount.ResultsfortheFinancialyear(), false); // Retained Earnings
        UpdateTotalling('M-BALANCE', 'P0024', CreateGLAccount.NetResults(), false); // Distribution to Shareholders

        // Cash Flow Statement
        UpdateTotalling('M-CASHFLOW', 'P0002', CreateGLAccount.SalesofServiceWork() + '..' + CreateGLAccount.SalesReturns(), false); // Net Income
        UpdateTotalling('M-CASHFLOW', 'P0003', '', false); // Adjustments
        UpdateTotalling('M-CASHFLOW', 'P0004', CreateGLAccount.AccountReceivableDomestic(), false); // Account Receivables
        UpdateTotalling('M-CASHFLOW', 'P0005', CreateGLAccount.PrepaidRent() + '..' + CreateGLAccount.Otherprepaidexpensesandaccruedincome(), false); // Prepaid Expences
        UpdateTotalling('M-CASHFLOW', 'P0006', CreateGLAccount.FinishedGoods(), false); // Inventory
        UpdateTotalling('M-CASHFLOW', 'P0007', CreateGLAccount.AccountsPayableDomestic() + '..' + CreateGLAccount.SalesTax_VATLiable(), false); // Current Liabilities
        UpdateTotalling('M-CASHFLOW', 'P0008', CreateGLAccount.TaxesLiable() + '..' + CreateGLAccount.OtherSalary_wageDeductions(), false); // Payroll Liabilities
        UpdateTotalling('M-CASHFLOW', 'P0012', CreateGLAccount.EquipmentsandTools(), false); // Equipment
        UpdateTotalling('M-CASHFLOW', 'P0013', CreateGLAccount.AccumulatedDepreciation(), false); // Accumulated Depreciation
        UpdateTotalling('M-CASHFLOW', 'P0017', CreateGLAccount.OtherLiabilities(), false); // Long Term Liabilities
        UpdateTotalling('M-CASHFLOW', 'P0018', CreateGLAccount.NetResults(), false); // Distribution to Shareholders
        UpdateTotalling('M-CASHFLOW', 'F0021', '', false); // Net Cash Increase for the Period
        UpdateTotalling('M-CASHFLOW', 'P0022', '', false); // Cash at the Beginning of Period

        // Income Statement
        UpdateTotalling('M-INCOME', 'P0002', CreateGLAccount.SalesofServiceWork(), false); // Income Services
        UpdateTotalling('M-INCOME', 'P0003', CreateGLAccount.SalesofGoods(), false); // Income Products
        UpdateTotalling('M-INCOME', 'P0004', CreateGLAccount.SalesDiscounts(), false); // Sales Discounts
        UpdateTotalling('M-INCOME', 'P0005', CreateGLAccount.SalesReturns(), false); // Sales returns and Allowances
        UpdateTotalling('M-INCOME', 'P0009', CreateGLAccount.CostofLabor(), false); // Labor
        UpdateTotalling('M-INCOME', 'P0010', CreateGLAccount.CostofMaterials(), false); // Materials
        UpdateTotalling('M-INCOME', 'P0016', CreateGLAccount.Rent_Leases(), false); // Rent Expences
        UpdateTotalling('M-INCOME', 'P0017', CreateGLAccount.AdvertisementDevelopment(), false); // Advertising Expences
        UpdateTotalling('M-INCOME', 'P0018', CreateGLAccount.InterestExpenses(), false); // Interest Expences
        UpdateTotalling('M-INCOME', 'P0019', CreateGLAccount.Bankingfees(), false); // Fees Expences
        UpdateTotalling('M-INCOME', 'P0020', CreateGLAccount.BadDebtLosses(), false); // Insurance Expences
        UpdateTotalling('M-INCOME', 'P0021', CreateGLAccount.Salaries() + '..' + CreateGLAccount.WorkersCompensation(), false); // Payroll Expences
        UpdateTotalling('M-INCOME', 'P0022', CreateGLAccount.HealthInsurance() + '..' + CreateGLAccount.LifeInsurance(), false); // Benefits Expences
        UpdateTotalling('M-INCOME', 'P0023', CreateGLAccount.RepairsandMaintenanceforRental(), false); // Repairs Expences
        UpdateTotalling('M-INCOME', 'P0024', CreateGLAccount.ElectricityforRental(), false); // Utilities Expences
        UpdateTotalling('M-INCOME', 'P0025', CreateGLAccount.OfficeSupplies() + '..' + CreateGLAccount.DepreciationFixedAssets(), false); // Other Expences
        UpdateTotalling('M-INCOME', 'P0026', CreateGLAccount.FederalPersonnelTaxes() + '..' + CreateGLAccount.TotalStatePersonnelTaxes(), false); // Tax Expences

        // Retained Earnings
        UpdateTotalling('M-RETAIND', 'P0001', CreateGLAccount.ResultsfortheFinancialyear(), false); // Retained Earnings primo
        UpdateTotalling('M-RETAIND', 'P0002', CreateGLAccount.SalesofServiceWork() + '..' + CreateGLAccount.SalesReturns(), false); // Net Income
        UpdateTotalling('M-RETAIND', 'P0005', CreateGLAccount.NetResults(), false); // Distribution to Shareholders
    end;

    local procedure UpdateTotalling(ScheduleName: Code[20]; RowNo: Code[10]; Totalling: Text[250]; IsFormula: Boolean)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        AccScheduleLine.SetRange("Schedule Name", ScheduleName);
        AccScheduleLine.SetRange("Row No.", RowNo);
        AccScheduleLine.FindFirst();
        if IsFormula then
            AccScheduleLine."Totaling Type" := AccScheduleLine."Totaling Type"::Formula
        else
            AccScheduleLine."Totaling Type" := AccScheduleLine."Totaling Type"::"Posting Accounts";
        AccScheduleLine.Totaling := Totalling;
        AccScheduleLine.Modify();
    end;

    var
        CreateGLAccount: Codeunit "Create G/L Account";
}

