namespace System.Security.AccessControl;

using Microsoft.Bank.ElectronicFundsTransfer;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Foundation.Address;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Address Buffer" = RIMD,
                  tabledata "Address ID" = RIMD,
                  tabledata "BAS Business Unit" = RIMD,
                  tabledata "BAS Calc. Sheet Entry" = RIMD,
                  tabledata "BAS Calculation Sheet" = RIMD,
                  tabledata "BAS Comment Line" = RIMD,
                  tabledata "BAS Setup" = RIMD,
                  tabledata "BAS Setup Name" = RIMD,
                  tabledata "BAS XML Field ID" = RIMD,
                  tabledata "BAS XML Field ID Setup" = RIMD,
                  tabledata "BAS XML Field Setup Name" = RIMD,
                  tabledata County = RIMD,
                  tabledata "EFT Register" = RIMD,
                  tabledata "GST Purchase Entry" = RIMD,
                  tabledata "GST Sales Entry" = RIMD,
                  tabledata "Post Dated Check Line" = RIMD,
                  tabledata "Purch. Tax Cr. Memo Hdr." = RIMD,
                  tabledata "Purch. Tax Cr. Memo Line" = RIMD,
                  tabledata "Purch. Tax Inv. Header" = RIMD,
                  tabledata "Purch. Tax Inv. Line" = RIMD,
                  tabledata "Sales Tax Cr.Memo Header" = RIMD,
                  tabledata "Sales Tax Cr.Memo Line" = RIMD,
                  tabledata "Sales Tax Invoice Header" = RIMD,
                  tabledata "Sales Tax Invoice Line" = RIMD,
                  tabledata "Tax Document Buffer" = RIMD,
                  tabledata "Tax Document Buffer Build" = RIMD,
                  tabledata "Tax Posting Buffer" = RIMD,
                  tabledata "Temp WHT Entry - EFiling" = RIMD,
                  tabledata "Temp WHT Entry" = RIMD,
                  tabledata "WHT Business Posting Group" = RIMD,
                  tabledata "WHT Certificate Buffer" = RIMD,
                  tabledata "WHT Entry" = RIMD,
                  tabledata "WHT Posting Setup" = RIMD,
                  tabledata "WHT Product Posting Group" = RIMD,
                  tabledata "WHT Revenue Types" = RIMD;
}
