// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Individual line data for VAT reports containing detailed VAT entry information.
/// Stores VAT transaction details used for generating VAT returns and regulatory submissions.
/// </summary>
table 741 "VAT Report Line"
{
    Caption = 'VAT Report Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Reference to the VAT report header this line belongs to.
        /// </summary>
        field(1; "VAT Report No."; Code[20])
        {
            Caption = 'VAT Report No.';
            Editable = false;
            TableRelation = "VAT Report Header"."No.";
        }
        /// <summary>
        /// Sequential line number within the VAT report for ordering and identification.
        /// </summary>
        field(2; "Line No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// General product posting group from the original VAT entry transaction.
        /// </summary>
        field(3; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            Editable = false;
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// Posting date of the original VAT entry transaction.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the document that resulted in the VAT entry.';
            Editable = false;
        }
        /// <summary>
        /// Document number from the original VAT entry transaction.
        /// </summary>
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number that resulted in the VAT entry.';
            Editable = false;
        }
        /// <summary>
        /// Document type from the original VAT entry transaction.
        /// </summary>
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of the document that resulted in the VAT entry.';
            Editable = false;
        }
        /// <summary>
        /// General posting type indicating whether this is a sales or purchase VAT entry.
        /// </summary>
        field(7; Type; Enum "General Posting Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of the VAT entry.';
            Editable = false;
        }
        /// <summary>
        /// VAT base amount from the original VAT entry transaction.
        /// </summary>
        field(8; Base; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Base';
            ToolTip = 'Specifies the amount that the VAT amount in the Amount is calculated from.';
            Editable = false;
        }
        /// <summary>
        /// VAT amount from the original VAT entry transaction.
        /// </summary>
        field(9; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            ToolTip = 'Specifies the VAT amount for the report line. This is calculated based on the value of the Base field.';
            Editable = false;
        }
        /// <summary>
        /// VAT calculation type from the VAT posting setup used in the original transaction.
        /// </summary>
        field(10; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
            Editable = false;
        }
        /// <summary>
        /// Customer or vendor number from the original VAT entry transaction.
        /// </summary>
        field(12; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
            ToolTip = 'Specifies the number of the bill-to customer or pay-to vendor that the entry is linked to.';
            Editable = false;
            TableRelation = if (Type = const(Purchase)) Vendor
            else
            if (Type = const(Sale)) Customer;
        }
        /// <summary>
        /// Indicates whether the transaction was part of an EU 3-party trade arrangement.
        /// </summary>
        field(13; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
            Editable = false;
        }
        /// <summary>
        /// Source code from the original VAT entry indicating the transaction origin.
        /// </summary>
        field(15; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
            Editable = false;
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Reason code from the original VAT entry providing additional transaction context.
        /// </summary>
        field(16; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
            Editable = false;
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Country/region code from the original VAT entry for geographic reporting requirements.
        /// </summary>
        field(19; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            ToolTip = 'Specifies the country/region of the address.';
            Editable = false;
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Internal reference number from the original VAT entry for tracking and audit purposes.
        /// </summary>
        field(20; "Internal Ref. No."; Text[30])
        {
            Caption = 'Internal Ref. No.';
            ToolTip = 'Specifies the internal reference number of the VAT entry.';
            Editable = false;
        }
        /// <summary>
        /// Unrealized VAT amount for companies using cash-based VAT accounting.
        /// </summary>
        field(22; "Unrealized Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Unrealized Amount';
            ToolTip = 'Specifies the unrealized VAT amount for this line if you use unrealized VAT.';
            Editable = false;
        }
        /// <summary>
        /// Unrealized VAT base amount for companies using cash-based VAT accounting.
        /// </summary>
        field(23; "Unrealized Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Unrealized Base';
            ToolTip = 'Specifies the unrealized base amount if you use unrealized VAT.';
            Editable = false;
        }
        /// <summary>
        /// External document number from the original VAT entry transaction.
        /// </summary>
        field(26; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
            Editable = false;
        }
        /// <summary>
        /// VAT business posting group from the original VAT entry transaction.
        /// </summary>
        field(39; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            Editable = false;
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group from the original VAT entry transaction.
        /// </summary>
        field(40; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            Editable = false;
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// VAT registration number of the bill-to/pay-to party from the original transaction.
        /// </summary>
        field(55; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            ToolTip = 'Specifies the VAT registration number of the customer or vendor that the VAT entry is linked to.';
            Editable = false;
        }
        /// <summary>
        /// General business posting group from the original VAT entry transaction.
        /// </summary>
        field(56; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            Editable = false;
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// Unique record identifier for tracking and reference purposes in the VAT report.
        /// </summary>
        field(100; "Record Identifier"; Code[30])
        {
            Caption = 'Record Identifier';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "VAT Report No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportHeader.Get("VAT Report No.");

        if (VATReportHeader.Status = VATReportHeader.Status::Released) and
           (not VATReportSetup."Modify Submitted Reports")
        then
            Error(Text001, VATReportSetup.TableCaption());
    end;

    var
        VATReportHeader: Record "VAT Report Header";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'This is not allowed because of the setup in the %1 window.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}
