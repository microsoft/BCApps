// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Temporary table for VAT entry posting preview functionality in Business Central.
/// Stores VAT transaction data during posting preview without committing to the actual VAT Entry table.
/// </summary>
/// <remarks>
/// Used by posting preview infrastructure to show VAT entries that would be created during posting.
/// Contains the same field structure as VAT Entry table but operates as temporary storage.
/// Integrates with General Ledger posting preview and document posting workflows.
/// </remarks>
table 1571 "VAT Entry Posting Preview"
{
    Caption = 'VAT Entry';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        /// <summary>
        /// Unique sequential identifier for the VAT entry posting preview record.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        /// <summary>
        /// General business posting group for trade type categorization in posting setup.
        /// </summary>
        field(2; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            Editable = false;
            TableRelation = "Gen. Business Posting Group";
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
        }
        /// <summary>
        /// General product posting group for item type categorization in posting setup.
        /// </summary>
        field(3; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            Editable = false;
            TableRelation = "Gen. Product Posting Group";
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
        }
        /// <summary>
        /// Date when the VAT transaction will be posted to the ledger.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
            ToolTip = 'Specifies the VAT entry''s posting date.';
        }
        /// <summary>
        /// Document number associated with the VAT transaction.
        /// </summary>
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
            ToolTip = 'Specifies the document number on the VAT entry.';
        }
        /// <summary>
        /// Type of document generating the VAT entry (Invoice, Credit Memo, etc.).
        /// </summary>
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
            ToolTip = 'Specifies the document type that the VAT entry belongs to.';
        }
        /// <summary>
        /// General posting type indicating whether transaction is Sales or Purchase VAT.
        /// </summary>
        field(7; Type; Enum "General Posting Type")
        {
            Caption = 'Type';
            Editable = false;
            ToolTip = 'Specifies the type of the VAT entry.';
        }
        /// <summary>
        /// Base amount used for VAT calculation in local currency.
        /// </summary>
        field(8; Base; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Base';
            Editable = false;
            ToolTip = 'Specifies the amount that the VAT amount (the amount shown in the Amount field) is calculated from.';
        }
        /// <summary>
        /// Calculated VAT amount in local currency.
        /// </summary>
        field(9; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            Editable = false;
            ToolTip = 'Specifies the amount of the VAT entry in LCY.';
        }
        /// <summary>
        /// Method used for calculating VAT (Normal VAT, Reverse Charge, etc.).
        /// </summary>
        field(10; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
            ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
        }
        /// <summary>
        /// Customer or vendor number linked to this VAT transaction.
        /// </summary>
        field(12; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
            TableRelation = if (Type = const(Purchase)) Vendor
            else
            if (Type = const(Sale)) Customer;
            ToolTip = 'Specifies the number of the bill-to customer or pay-to vendor that the entry is linked to.';
        }
        /// <summary>
        /// Indicates whether the transaction involves EU triangular trade with third parties.
        /// </summary>
        field(13; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
        }
        /// <summary>
        /// User ID of the person who created this VAT entry preview.
        /// </summary>
        field(14; "User ID"; Code[50])
        {
            Caption = 'User ID';
            Editable = false;
        }
        /// <summary>
        /// Source code identifying the module or process that created this entry.
        /// </summary>
        field(15; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Reason code providing additional classification for the transaction.
        /// </summary>
        field(16; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            Editable = false;
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Entry number of the VAT entry that closed this entry through VAT settlement.
        /// </summary>
        field(17; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            Editable = false;
            TableRelation = "VAT Entry";
            ToolTip = 'Specifies the number of the VAT entry that has closed the entry, if the VAT entry was closed with the Calc. and Post VAT Settlement batch job.';
        }
        /// <summary>
        /// Indicates whether this VAT entry has been closed by VAT settlement processing.
        /// </summary>
        field(18; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
            ToolTip = 'Specifies whether the VAT entry has been closed by the Calc. and Post VAT Settlement batch job.';
        }
        /// <summary>
        /// Country or region code for VAT reporting and jurisdiction purposes.
        /// </summary>
        field(19; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country/region of the address.';
        }
        /// <summary>
        /// Internal reference number for additional transaction tracking.
        /// </summary>
        field(20; "Internal Ref. No."; Text[30])
        {
            Caption = 'Internal Ref. No.';
            Editable = false;
            ToolTip = 'Specifies the internal reference number for the line.';
        }
        /// <summary>
        /// Transaction number linking related entries within the same posting batch.
        /// </summary>
        field(21; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Unrealized VAT amount for cash-based VAT accounting.
        /// </summary>
        field(22; "Unrealized Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Unrealized Amount';
            Editable = false;
        }
        /// <summary>
        /// Unrealized VAT base amount for cash-based VAT accounting.
        /// </summary>
        field(23; "Unrealized Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Unrealized Base';
            Editable = false;
        }
        /// <summary>
        /// Remaining unrealized VAT amount pending realization through payment.
        /// </summary>
        field(24; "Remaining Unrealized Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Remaining Unrealized Amount';
            Editable = false;
        }
        /// <summary>
        /// Remaining unrealized VAT base amount pending realization through payment.
        /// </summary>
        field(25; "Remaining Unrealized Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Remaining Unrealized Base';
            Editable = false;
        }
        /// <summary>
        /// External document number from the source system or trading partner.
        /// </summary>
        field(26; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            Editable = false;
        }
        /// <summary>
        /// Number series used for generating the document number.
        /// </summary>
        field(28; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Tax area code for sales tax jurisdiction in North American localization.
        /// </summary>
        field(29; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            Editable = false;
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the customer or item is liable for sales tax.
        /// </summary>
        field(30; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            Editable = false;
        }
        /// <summary>
        /// Tax group code for sales tax classification in North American localization.
        /// </summary>
        field(31; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            Editable = false;
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Indicates whether this is a use tax transaction for purchase tax.
        /// </summary>
        field(32; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            Editable = false;
        }
        /// <summary>
        /// Tax jurisdiction code for detailed tax authority classification.
        /// </summary>
        field(33; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            Editable = false;
            TableRelation = "Tax Jurisdiction";
        }
        /// <summary>
        /// Actual tax group used in calculation, may differ from default tax group.
        /// </summary>
        field(34; "Tax Group Used"; Code[20])
        {
            Caption = 'Tax Group Used';
            Editable = false;
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Type of tax calculation (Sales Tax or Excise Tax).
        /// </summary>
        field(35; "Tax Type"; Option)
        {
            Caption = 'Tax Type';
            Editable = false;
            OptionCaption = 'Sales Tax,Excise Tax';
            OptionMembers = "Sales Tax","Excise Tax";
        }
        /// <summary>
        /// Indicates whether tax is calculated on top of another tax.
        /// </summary>
        field(36; "Tax on Tax"; Boolean)
        {
            Caption = 'Tax on Tax';
            Editable = false;
        }
        /// <summary>
        /// Connection number linking to sales tax calculation engine.
        /// </summary>
        field(37; "Sales Tax Connection No."; Integer)
        {
            Caption = 'Sales Tax Connection No.';
            Editable = false;
        }
        /// <summary>
        /// Entry number of the related unrealized VAT entry.
        /// </summary>
        field(38; "Unrealized VAT Entry No."; Integer)
        {
            Caption = 'Unrealized VAT Entry No.';
            Editable = false;
            TableRelation = "VAT Entry";
        }
        /// <summary>
        /// VAT business posting group determining customer or vendor VAT treatment.
        /// </summary>
        field(39; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            Editable = false;
            TableRelation = "VAT Business Posting Group";
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
        }
        /// <summary>
        /// VAT product posting group determining item or service VAT treatment.
        /// </summary>
        field(40; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            Editable = false;
            TableRelation = "VAT Product Posting Group";
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
        }
        /// <summary>
        /// VAT amount in additional reporting currency.
        /// </summary>
        field(43; "Additional-Currency Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            Editable = false;
            ToolTip = 'Specifies the amount of the VAT entry. The amount is in the additional reporting currency.';
        }
        /// <summary>
        /// VAT base amount in additional reporting currency.
        /// </summary>
        field(44; "Additional-Currency Base"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Base';
            Editable = false;
            ToolTip = 'Specifies the amount that the VAT amount is calculated from if you post in an additional reporting currency.';
        }
        /// <summary>
        /// Unrealized VAT amount in additional reporting currency.
        /// </summary>
        field(45; "Add.-Currency Unrealized Amt."; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Unrealized Amt.';
            Editable = false;
        }
        /// <summary>
        /// Unrealized VAT base amount in additional reporting currency.
        /// </summary>
        field(46; "Add.-Currency Unrealized Base"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Unrealized Base';
            Editable = false;
        }
        /// <summary>
        /// Percentage discount applied to VAT base amount before VAT calculation.
        /// </summary>
        field(48; "VAT Base Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Remaining unrealized VAT amount in additional reporting currency.
        /// </summary>
        field(49; "Add.-Curr. Rem. Unreal. Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Rem. Unreal. Amount';
            Editable = false;
        }
        /// <summary>
        /// Remaining unrealized VAT base amount in additional reporting currency.
        /// </summary>
        field(50; "Add.-Curr. Rem. Unreal. Base"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Rem. Unreal. Base';
            Editable = false;
        }
        /// <summary>
        /// Manual VAT difference adjustment applied to calculated VAT amount.
        /// </summary>
        field(51; "VAT Difference"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Difference';
            Editable = false;
            ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
        }
        /// <summary>
        /// VAT difference adjustment in additional reporting currency.
        /// </summary>
        field(52; "Add.-Curr. VAT Difference"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. VAT Difference';
            Editable = false;
            ToolTip = 'Specifies, in the additional reporting currency, the VAT difference that arises when you make a correction to a VAT amount on a sales or purchase document.';
        }
        /// <summary>
        /// Address code for ship-to or order-from address associated with transaction.
        /// </summary>
        field(53; "Ship-to/Order Address Code"; Code[10])
        {
            Caption = 'Ship-to/Order Address Code';
            TableRelation = if (Type = const(Purchase)) "Order Address".Code where("Vendor No." = field("Bill-to/Pay-to No."))
            else
            if (Type = const(Sale)) "Ship-to Address".Code where("Customer No." = field("Bill-to/Pay-to No."));
            ToolTip = 'Specifies the address code of the ship-to customer or order-from vendor that the entry is linked to.';
        }
        /// <summary>
        /// Date of the original source document generating this VAT entry.
        /// </summary>
        field(54; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
            ToolTip = 'Specifies the date when the related document was created.';
        }
        /// <summary>
        /// VAT registration number of the customer or vendor for VAT reporting.
        /// </summary>
        field(55; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            ToolTip = 'Specifies the VAT registration number of the customer or vendor that the entry is linked to.';
        }
        /// <summary>
        /// Indicates whether this entry has been reversed through a correction transaction.
        /// </summary>
        field(56; Reversed; Boolean)
        {
            Caption = 'Reversed';
            ToolTip = 'Specifies if the entry has been part of a reverse transaction.';
        }
        /// <summary>
        /// Entry number of the VAT entry that reversed this entry.
        /// </summary>
        field(57; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "VAT Entry";
            ToolTip = 'Specifies the number of the correcting entry. If the field Specifies a number, the entry cannot be reversed again.';
        }
        /// <summary>
        /// Entry number of the original VAT entry that this entry reverses.
        /// </summary>
        field(58; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "VAT Entry";
            ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
        }
        /// <summary>
        /// Indicates whether this VAT entry relates to EU service transactions for reporting.
        /// </summary>
        field(59; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
            Editable = false;
            ToolTip = 'Specifies if this VAT entry is to be reported as a service in the periodic VAT reports.';
        }
        /// <summary>
        /// VAT base amount before payment discount was applied.
        /// </summary>
        field(60; "Base Before Pmt. Disc."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Base Before Pmt. Disc.';
            Editable = false;
        }
        /// <summary>
        /// Realized VAT amount for cash-based VAT accounting.
        /// </summary>
        field(81; "Realized Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Realized Amount';
            Editable = false;
        }
        /// <summary>
        /// Realized VAT base amount for cash-based VAT accounting.
        /// </summary>
        field(82; "Realized Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Realized Base';
            Editable = false;
        }
        /// <summary>
        /// Realized VAT amount in additional reporting currency.
        /// </summary>
        field(83; "Add.-Curr. Realized Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Realized Amount';
            Editable = false;
        }
        /// <summary>
        /// Realized VAT base amount in additional reporting currency.
        /// </summary>
        field(84; "Add.-Curr. Realized Base"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Realized Base';
            Editable = false;
        }
        /// <summary>
        /// Indentation level for hierarchical display in posting preview.
        /// </summary>
        field(1570; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        /// <summary>
        /// Reference to the source VAT entry number for preview traceability.
        /// </summary>
        field(1571; "VAT Entry No."; Integer)
        {
            Caption = 'VAT Entry No.';
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Posting Date", "Document Type", "Document No.", "Posting Date")
        {
        }
    }

    var
        GLSetup: Record "General Ledger Setup";
        GLSetupRead: Boolean;

    /// <summary>
    /// Retrieves the additional reporting currency code from General Ledger Setup.
    /// </summary>
    /// <returns>Additional reporting currency code or empty string if not configured</returns>
    local procedure GetCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;
}
