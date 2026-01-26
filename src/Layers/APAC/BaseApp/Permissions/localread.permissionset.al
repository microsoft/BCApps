namespace System.Security.AccessControl;

using Microsoft.Bank.ElectronicFundsTransfer;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Foundation.Address;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "Address Buffer" = R,
                  tabledata "Address ID" = R,
                  tabledata "BAS Business Unit" = R,
                  tabledata "BAS Calc. Sheet Entry" = R,
                  tabledata "BAS Calculation Sheet" = R,
                  tabledata "BAS Comment Line" = R,
                  tabledata "BAS Setup" = R,
                  tabledata "BAS Setup Name" = R,
                  tabledata "BAS XML Field ID" = R,
                  tabledata "BAS XML Field ID Setup" = R,
                  tabledata "BAS XML Field Setup Name" = R,
                  tabledata County = R,
                  tabledata "EFT Register" = R,
                  tabledata "GST Purchase Entry" = R,
                  tabledata "GST Sales Entry" = R,
                  tabledata "Post Dated Check Line" = R,
                  tabledata "Purch. Tax Cr. Memo Hdr." = R,
                  tabledata "Purch. Tax Cr. Memo Line" = R,
                  tabledata "Purch. Tax Inv. Header" = R,
                  tabledata "Purch. Tax Inv. Line" = R,
                  tabledata "Sales Tax Cr.Memo Header" = R,
                  tabledata "Sales Tax Cr.Memo Line" = R,
                  tabledata "Sales Tax Invoice Header" = R,
                  tabledata "Sales Tax Invoice Line" = R,
                  tabledata "Tax Document Buffer" = R,
                  tabledata "Tax Document Buffer Build" = R,
                  tabledata "Tax Posting Buffer" = R,
                  tabledata "Temp WHT Entry - EFiling" = R,
                  tabledata "Temp WHT Entry" = R,
                  tabledata "WHT Business Posting Group" = R,
                  tabledata "WHT Certificate Buffer" = R,
                  tabledata "WHT Entry" = R,
                  tabledata "WHT Posting Setup" = R,
                  tabledata "WHT Product Posting Group" = R,
                  tabledata "WHT Revenue Types" = R;
}
