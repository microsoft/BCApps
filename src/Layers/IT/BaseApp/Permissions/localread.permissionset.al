namespace System.Security.AccessControl;

using Microsoft;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.TransactionNature;
using Microsoft.Finance.WithholdingTax;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
#if not CLEAN27
using Microsoft.Manufacturing.Document;
#endif
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "ABI/CAB Codes" = R,
                  tabledata "Activity Code" = R,
                  tabledata "Appointment Code" = R,
                  tabledata "Before Start Item Cost" = R,
                  tabledata Bill = R,
                  tabledata "Bill Posting Group" = R,
                  tabledata "Blacklist Comm. Amount" = R,
                  tabledata "Check Fiscal Code Setup" = R,
                  tabledata "Company Officials" = R,
                  tabledata "Company Types" = R,
                  tabledata "Compress Depreciation" = R,
                  tabledata "Computed Contribution" = R,
                  tabledata "Computed Withholding Tax" = R,
                  tabledata "Contribution Bracket" = R,
                  tabledata "Contribution Bracket Line" = R,
                  tabledata "Contribution Code" = R,
                  tabledata "Contribution Code Line" = R,
                  tabledata "Contribution Payment" = R,
                  tabledata Contributions = R,
                  tabledata "Customer Bill Header" = R,
                  tabledata "Customer Bill Line" = R,
                  tabledata "Customs Authority Vendor" = R,
                  tabledata "Customs Office" = R,
                  tabledata "Deferring Due Dates" = R,
                  tabledata "Document Relation" = R,
                  tabledata "Fattura Code" = R,
                  tabledata "Fattura Document Type" = R,
                  tabledata "Fattura Header" = R,
                  tabledata "Fattura Line" = R,
                  tabledata "Fattura Project Info" = R,
                  tabledata "Fattura Setup" = R,
                  tabledata "Fixed Due Dates" = R,
                  tabledata "GL Book Entry" = R,
                  tabledata "Goods Appearance" = R,
                  tabledata "Incl. in VAT Report Error Log" = R,
                  tabledata "Interest on Arrears" = R,
                  tabledata "Issued Customer Bill Header" = R,
                  tabledata "Issued Customer Bill Line" = R,
                  tabledata "Item Cost History" = R,
                  tabledata "Item Costing Setup" = R,
                  tabledata "Lifo Band" = R,
                  tabledata "Lifo Category" = R,
                  tabledata "Payment Lines" = R,
#if not CLEAN27
                  tabledata "Periodic Settlement VAT Entry" = R,
#endif
                  tabledata "Periodic VAT Settlement Entry" = R,
                  tabledata "Posted Payment Lines" = R,
                  tabledata "Posted Vendor Bill Header" = R,
                  tabledata "Posted Vendor Bill Line" = R,
                  tabledata "Purch. Withh. Contribution" = R,
                  tabledata "Reprint Info Fiscal Reports" = R,
                  tabledata "Service Tariff Number" = R,
                  tabledata "Spesometro Appointment" = R,
#if not CLEAN27
                  tabledata "Subcontractor Prices" = R,
#endif
                  tabledata "Tmp Withholding Contribution" = R,
                  tabledata "Transport Reason Code" = R,
                  tabledata "VAT Book Entry" = R,
                  tabledata "VAT Exemption" = R,
                  tabledata "VAT Identifier" = R,
                  tabledata "VAT Plafond Period" = R,
                  tabledata "VAT Register - Buffer" = R,
                  tabledata "VAT Register" = R,
                  tabledata "VAT Transaction Nature" = R,
                  tabledata "VAT Transaction Report Amount" = R,
                  tabledata "Vendor Bill Header" = R,
                  tabledata "Vendor Bill Line" = R,
                  tabledata "Vendor Bill Withholding Tax" = R,
                  tabledata "Withhold Code" = R,
                  tabledata "Withhold Code Line" = R,
                  tabledata "Withholding Tax" = R,
                  tabledata "Withholding Tax Line" = R,
                  tabledata "Withholding Tax Payment" = R,
                  tabledata "Withholding Exceptional Event" = R;
}