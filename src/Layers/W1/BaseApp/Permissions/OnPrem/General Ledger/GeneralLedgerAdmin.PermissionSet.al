namespace System.Security.AccessControl;

using Microsoft.Utilities;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Location;
using Microsoft.Projects.TimeSheet;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Task;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using System.Environment.Configuration;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Analysis;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Currency;
using System.IO;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Foundation.NoSeries;
using System.Device;
using System.Xml;
using System.Security.User;
using System.Automation;
using Microsoft.Foundation.Period;
using Microsoft.Integration.Graph;
using Microsoft.Foundation.Calendar;

permissionset 4423 "General Ledger - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'G/L setup';

    Permissions = tabledata "Object Options" = RIMD,
                  tabledata User = R,
                  tabledata "Acc. Sched. KPI Web Srv. Line" = RIMD,
                  tabledata "Acc. Sched. KPI Web Srv. Setup" = RIMD,
                  tabledata "Accounting Period" = RI,
                  tabledata "Activity Log" = RIMD,
                  tabledata "Alloc. Account Distribution" = R,
                  tabledata "Allocation Account" = R,
                  tabledata "Allocation Line" = RIMD,
                  tabledata "Alloc. Acc. Manual Override" = RIMD,
                  tabledata "Analysis View" = RIMD,
                  tabledata "Analysis View Filter" = RIMD,
                  tabledata "Attachment Entity Buffer" = RIMD,
                  tabledata "Bank Account Posting Group" = RIMD,
                  tabledata "Bank Export/Import Setup" = RIMD,
                  tabledata "Base Calendar" = RIMD,
                  tabledata "Base Calendar Change" = RIMD,
                  tabledata "Company Information" = RIMD,
                  tabledata "Country/Region" = RIMD,
                  tabledata Currency = RIMD,
                  tabledata "Currency Exchange Rate" = RIMD,
                  tabledata "Customized Calendar Change" = RIMD,
                  tabledata "Customized Calendar Entry" = RIMD,
                  tabledata "Data Exch." = Rimd,
                  tabledata "Data Exch. Column Def" = R,
                  tabledata "Data Exch. Def" = R,
                  tabledata "Data Exch. Field" = Rimd,
                  tabledata "Data Exch. Field Mapping" = R,
                  tabledata "Data Exch. Line Def" = R,
                  tabledata "Data Exch. Mapping" = R,
                  tabledata "Data Exch. Field Grouping" = R,
                  tabledata "Data Exch. FlowField Gr. Buff." = R,
                  tabledata "Data Exchange Type" = Rimd,
                  tabledata "Data Exch. Table Filter" = Rimd,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Default Dimension Priority" = RIMD,
                  tabledata Dimension = RIMD,
                  tabledata "Dimension Combination" = RIMD,
                  tabledata "Dimension Translation" = RIMD,
                  tabledata "Dimension Value" = RIMD,
                  tabledata "Dimension Value Combination" = RIMD,
                  tabledata "Dimensions Field Map" = Rimd,
                  tabledata "Dynamic Request Page Entity" = RIMD,
                  tabledata "Dynamic Request Page Field" = RIMD,
                  tabledata "Employee Time Reg Buffer" = RIMD,
                  tabledata "Extended Text Header" = RIMD,
                  tabledata "Extended Text Line" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Business Posting Group" = RIMD,
                  tabledata "Gen. Jnl. Allocation" = D,
                  tabledata "Gen. Journal Batch" = RIMD,
                  tabledata "Gen. Journal Line" = MD,
                  tabledata "Gen. Journal Template" = RIMD,
                  tabledata "Gen. Product Posting Group" = RIMD,
                  tabledata "General Ledger Setup" = RIMD,
                  tabledata "General Posting Setup" = RIMD,
                  tabledata "IC Bank Account" = RIMD,
                  tabledata "IC Dimension" = RIMD,
                  tabledata "IC Dimension Value" = RIMD,
                  tabledata "IC G/L Account" = RIMD,
                  tabledata "IC Partner" = RIMD,
                  tabledata "IC Setup" = RIMD,
                  tabledata "Incoming Document" = RIMD,
                  tabledata "Incoming Document Approver" = RIMD,
                  tabledata "Incoming Document Attachment" = RIMD,
                  tabledata "Incoming Documents Setup" = RIMD,
                  tabledata "Intermediate Data Import" = Rimd,
                  tabledata "No. Series" = RIMD,
                  tabledata "No. Series Line" = RIMD,
                  tabledata "No. Series Relationship" = RIMD,
                  tabledata "Notification Schedule" = RIMD,
                  tabledata "Notification Setup" = RIMD,
                  tabledata "Post Code" = RIMD,
                  tabledata "Posted Docs. With No Inc. Buf." = RIMD,
                  tabledata "Printer Selection" = RIMD,
                  tabledata "Reason Code" = RIMD,
                  tabledata "Referenced XML Schema" = RIMD,
                  tabledata "Responsibility Center" = RIMD,
                  tabledata "Source Code" = RIMD,
                  tabledata "Source Code Setup" = RIMD,
                  tabledata "Standard Text" = RIMD,
                  tabledata Territory = RIMD,
                  tabledata "Unlinked Attachment" = RIMD,
                  tabledata "User Setup" = RIMD,
                  tabledata "User Task Group" = RIMD,
                  tabledata "User Task Group Member" = RIMD,
                  tabledata "User Time Register" = RIMD,
                  tabledata "VAT Assisted Setup Bus. Grp." = RIMD,
                  tabledata "VAT Assisted Setup Templates" = RIMD,
                  tabledata "VAT Business Posting Group" = RIMD,
                  tabledata "VAT Posting Setup" = RIMD,
                  tabledata "VAT Product Posting Group" = RIMD,
                  tabledata "VAT Rate Change Conversion" = RIMD,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = RIMD,
                  tabledata "VAT Report Setup" = RIMD,
                  tabledata "VAT Reporting Code" = RIMD,
                  tabledata "VAT Setup Posting Groups" = RIMD,
                  tabledata "VAT Setup" = RIMD,
                  tabledata "VAT Posting Parameters" = RIMD,
                  tabledata "VAT Statement Line" = RIMD,
                  tabledata "VAT Statement Name" = RIMD,
                  tabledata "VAT Statement Template" = RIMD,
                  tabledata "WF Event/Response Combination" = RIMD,
                  tabledata "Workflow - Record Change" = RIMD,
                  tabledata "Workflow - Table Relation" = RIMD,
                  tabledata Workflow = RIMD,
                  tabledata "Workflow Category" = RIMD,
                  tabledata "Workflow Event" = RIMD,
                  tabledata "Workflow Event Queue" = RIMD,
                  tabledata "Workflow Record Change Archive" = RIMD,
                  tabledata "Workflow Response" = RIMD,
                  tabledata "Workflow Rule" = RIMD,
                  tabledata "Workflow Step" = RIMD,
                  tabledata "Workflow Step Argument" = RIMD,
                  tabledata "Workflow Step Argument Archive" = RIMD,
                  tabledata "Workflow Step Buffer" = RIMD,
                  tabledata "Workflow Step Instance" = Rimd,
                  tabledata "Workflow Step Instance Archive" = RIMD,
                  tabledata "Workflow Table Relation Value" = Rimd,
                  tabledata "Workflow User Group" = RIMD,
                  tabledata "Workflow User Group Member" = RIMD,
                  tabledata "XML Buffer" = R,
                  tabledata "XML Schema" = RIMD,
                  tabledata "XML Schema Element" = RIMD,
                  tabledata "XML Schema Restriction" = RIMD;
}
