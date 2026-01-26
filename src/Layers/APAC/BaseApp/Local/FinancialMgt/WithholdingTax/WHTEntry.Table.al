// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Telemetry;

table 28044 "WHT Entry"
{
    Caption = 'WHT Entry';
    DrillDownPageID = "WHT Entry";
    LookupPageID = "WHT Entry";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            Editable = false;
            TableRelation = "Gen. Business Posting Group";
        }
        field(3; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            Editable = false;
            TableRelation = "Gen. Product Posting Group";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        field(8; Base; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base';
            Editable = false;
        }
        field(9; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        field(10; "WHT Calculation Type"; Option)
        {
            Caption = 'WHT Calculation Type';
            Editable = false;
            OptionCaption = 'Normal WHT,Full WHT';
            OptionMembers = "Normal WHT","Full WHT";
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(12; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
            TableRelation = if ("Transaction Type" = const(Purchase)) Vendor
            else
            if ("Transaction Type" = const(Sale)) Customer;
        }
        field(14; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(15; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(16; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            Editable = false;
            TableRelation = "Reason Code";
        }
        field(17; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            Editable = false;
            TableRelation = "WHT Entry";
        }
        field(18; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
        field(19; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                Validate("Transaction Type");
            end;
        }
        field(21; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        field(22; "Unrealized Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unrealized Amount';
            Editable = false;
        }
        field(23; "Unrealized Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unrealized Base';
            Editable = false;
        }
        field(24; "Remaining Unrealized Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Unrealized Amount';
            Editable = false;
        }
        field(25; "Remaining Unrealized Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Unrealized Base';
            Editable = false;
        }
        field(26; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            Editable = false;
        }
        field(27; "Transaction Type"; Option)
        {
            Caption = 'Transaction Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;
        }
        field(28; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(29; "Unrealized WHT Entry No."; Integer)
        {
            Caption = 'Unrealized WHT Entry No.';
            Editable = false;
            TableRelation = "WHT Entry";
        }
        field(30; "WHT Bus. Posting Group"; Code[20])
        {
            Caption = 'WHT Bus. Posting Group';
            Editable = false;
            TableRelation = "WHT Business Posting Group";
        }
        field(31; "WHT Prod. Posting Group"; Code[20])
        {
            Caption = 'WHT Prod. Posting Group';
            Editable = false;
            TableRelation = "WHT Product Posting Group";
        }
        field(32; "Base (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base (LCY)';
            Editable = false;
        }
        field(33; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
            Editable = false;
        }
        field(34; "Unrealized Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Unrealized Amount (LCY)';
            Editable = false;
        }
        field(35; "Unrealized Base (LCY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Unrealized Base (LCY)';
            Editable = false;
        }
        field(36; "WHT %"; Decimal)
        {
            Caption = 'WHT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(37; "Rem Unrealized Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Rem Unrealized Amount (LCY)';
            Editable = false;
        }
        field(38; "Rem Unrealized Base (LCY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Rem Unrealized Base (LCY)';
            Editable = false;
        }
        field(39; "WHT Difference"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'WHT Difference';
            Editable = false;
        }
        field(41; "Ship-to/Order Address Code"; Code[10])
        {
            Caption = 'Ship-to/Order Address Code';
            TableRelation = if ("Transaction Type" = const(Purchase)) "Order Address".Code where("Vendor No." = field("Bill-to/Pay-to No."))
            else
            if ("Transaction Type" = const(Sale)) "Ship-to Address".Code where("Customer No." = field("Bill-to/Pay-to No."));
        }
        field(42; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(44; "Actual Vendor No."; Code[20])
        {
            Caption = 'Actual Vendor No.';
        }
        field(45; "WHT Certificate No."; Code[20])
        {
            Caption = 'WHT Certificate No.';
        }
        field(47; "Void Check"; Boolean)
        {
            Caption = 'Void Check';
        }
        field(48; "Original Document No."; Code[20])
        {
            Caption = 'Original Document No.';
        }
        field(49; "Void Payment Entry No."; Integer)
        {
            Caption = 'Void Payment Entry No.';
        }
        field(50; "WHT Report Line No"; Code[20])
        {
            Caption = 'WHT Report Line No';
        }
        field(51; "WHT Report"; Option)
        {
            Caption = 'WHT Report';
            OptionCaption = ' ,Por Ngor Dor 1,Por Ngor Dor 2,Por Ngor Dor 3,Por Ngor Dor 53,Por Ngor Dor 54';
            OptionMembers = " ","Por Ngor Dor 1","Por Ngor Dor 2","Por Ngor Dor 3","Por Ngor Dor 53","Por Ngor Dor 54";
        }
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
        }
        field(54; "Applies-to Entry No."; Integer)
        {
            Caption = 'Applies-to Entry No.';
        }
        field(55; "WHT Revenue Type"; Code[10])
        {
            Caption = 'WHT Revenue Type';
            TableRelation = "WHT Revenue Types".Code;
        }
        field(56; Settled; Boolean)
        {
            Caption = 'Settled';
        }
        field(57; "Payment Amount"; Decimal)
        {
            Caption = 'Payment Amount';
        }
        field(58; "Reversed by Entry No."; Integer)
        {
            Caption = 'Reversed by Entry No.';
            TableRelation = "WHT Entry"."Entry No.";
        }
        field(59; "Reversed Entry No."; Integer)
        {
            Caption = 'Reversed Entry No.';
            TableRelation = "WHT Entry"."Entry No.";
        }
        field(60; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(61; "Rem Realized Amount"; Decimal)
        {
            Caption = 'Rem Realized Amount';
            Editable = false;
        }
        field(62; "Rem Realized Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            Caption = 'Rem Realized Amount (LCY)';
            Editable = false;
        }
        field(63; "Rem Realized Base"; Decimal)
        {
            Caption = 'Rem Realized Base';
            Editable = false;
        }
        field(64; "Rem Realized Base (LCY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            Caption = 'Rem Realized Base (LCY)';
            Editable = false;
        }
        field(65; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
        }
        field(28101; "Pymt. Disc. Diff. Base"; Decimal)
        {
            Caption = 'Pymt. Disc. Diff. Base';
        }
        field(28102; "Pymt. Disc. Diff. Amount"; Decimal)
        {
            Caption = 'Pymt. Disc. Diff. Amount';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Transaction Type", Closed, "WHT Difference", "Amount (LCY)", "Base (LCY)", "Posting Date")
        {
            SumIndexFields = Base, Amount, "Unrealized Amount", "Unrealized Base", "Unrealized Base (LCY)", "Unrealized Amount (LCY)";
        }
        key(Key3; "Transaction Type", "Country/Region Code", "WHT Difference", "Posting Date")
        {
            SumIndexFields = Base;
        }
        key(Key4; "Document No.", "Posting Date")
        {
        }
        key(Key5; "Transaction No.")
        {
        }
        key(Key6; "Amount (LCY)", "Unrealized Amount (LCY)", "Unrealized Base (LCY)", "Base (LCY)", "Posting Date")
        {
        }
        key(Key7; "Document Type", "Document No.")
        {
            SumIndexFields = Base, Amount, "Unrealized Amount", "Unrealized Base", "Remaining Unrealized Amount", "Remaining Unrealized Base", "Base (LCY)", "Amount (LCY)", "Unrealized Amount (LCY)", "Unrealized Base (LCY)", "Rem Unrealized Amount (LCY)", "Rem Unrealized Base (LCY)";
        }
        key(Key8; "Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.", Closed)
        {
            SumIndexFields = "Unrealized Base (LCY)";
        }
        key(Key9; "Applies-to Entry No.")
        {
            SumIndexFields = Base, Amount, "Unrealized Amount", "Unrealized Base", "Remaining Unrealized Amount", "Remaining Unrealized Base", "Base (LCY)", "Amount (LCY)", "Unrealized Amount (LCY)", "Unrealized Base (LCY)", "Rem Unrealized Amount (LCY)", "Rem Unrealized Base (LCY)";
        }
        key(Key10; "Bill-to/Pay-to No.", "Original Document No.", "WHT Revenue Type")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key11; "Bill-to/Pay-to No.", "WHT Revenue Type", "WHT Prod. Posting Group")
        {
        }
        key(Key12; "Bill-to/Pay-to No.", "WHT Bus. Posting Group", "WHT Revenue Type")
        {
        }
        key(Key13; "Document Type", "Transaction Type", Settled, "WHT Bus. Posting Group", "WHT Prod. Posting Group", "Posting Date")
        {
            SumIndexFields = Base, Amount, "Unrealized Amount", "Unrealized Base", "Remaining Unrealized Amount", "Remaining Unrealized Base", "Base (LCY)", "Amount (LCY)", "Unrealized Amount (LCY)", "Unrealized Base (LCY)", "Rem Unrealized Amount (LCY)", "Rem Unrealized Base (LCY)";
        }
        key(Key14; "Posting Date", Settled, "WHT Certificate No.")
        {
            SumIndexFields = Base, Amount, "Unrealized Amount", "Unrealized Base", "Remaining Unrealized Amount", "Remaining Unrealized Base", "Base (LCY)", "Amount (LCY)", "Unrealized Amount (LCY)", "Unrealized Base (LCY)", "Rem Unrealized Amount (LCY)", "Rem Unrealized Base (LCY)";
        }
        key(Key15; "Posting Date", "WHT Certificate No.")
        {
            SumIndexFields = Base, Amount, "Unrealized Amount", "Unrealized Base", "Remaining Unrealized Amount", "Remaining Unrealized Base", "Base (LCY)", "Amount (LCY)", "Unrealized Amount (LCY)", "Unrealized Base (LCY)", "Rem Unrealized Amount (LCY)", "Rem Unrealized Base (LCY)";
        }
        key(Key16; "Document Type", "Transaction Type", "Bill-to/Pay-to No.", "Transaction No.")
        {
            SumIndexFields = Base, Amount, "Unrealized Amount", "Unrealized Base", "Remaining Unrealized Amount", "Remaining Unrealized Base", "Base (LCY)", "Amount (LCY)", "Unrealized Amount (LCY)", "Unrealized Base (LCY)", "Rem Unrealized Amount (LCY)", "Rem Unrealized Base (LCY)";
        }
        key(Key17; "Transaction Type", "Bill-to/Pay-to No.", "Transaction No.")
        {
            SumIndexFields = "Rem Unrealized Amount (LCY)", "Unrealized Base (LCY)";
        }
        key(Key18; "WHT Revenue Type", "Posting Date")
        {
        }
        key(Key19; "Transaction Type", "Bill-to/Pay-to No.")
        {
            SumIndexFields = "Rem Unrealized Amount (LCY)";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Posting Date", "Document No.", Amount)
        {
        }
    }

    trigger OnInsert()
    begin
        FeatureTelemetry.LogUptake('0000HH4', APACWHTTok, Enum::"Feature Uptake Status"::"Used");
        FeatureTelemetry.LogUsage('0000HH5', APACWHTTok, 'APAC Withholding Tax Set Up');
    end;

    var
        GLSetup: Record "General Ledger Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        APACWHTTok: Label 'APAC Set Up Withholding Tax', Locked = true;
        GLSetupRead: Boolean;

    [Scope('OnPrem')]
    procedure GetCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;
}

