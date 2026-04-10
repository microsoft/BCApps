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

            trigger OnValidate()
            begin
                TestStatusOpen();
                CheckLineType();

                Base := RoundBase(Base);
            end;
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

            trigger OnValidate()
            begin
                TestStatusOpen();
                CheckLineType();

                Amount := RoundBase(Amount);
            end;
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
        field(17; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
            Editable = false;
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
        field(24; "Number of Supplies"; Decimal)
        {
            AutoFormatType = 0;
            BlankNumbers = DontBlank;
            Caption = 'Number of Supplies';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen();
                CheckLineType();
            end;
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
        field(30; "Trade Type"; Option)
        {
            Caption = 'Trade Type';
            Editable = false;
            OptionCaption = 'Purchase,Sale';
            OptionMembers = Purchase,Sale;

            trigger OnValidate()
            begin
                TestStatusOpen();
                CheckLineType();
            end;
        }
        field(31; "Line Type"; Option)
        {
            Caption = 'Line Type';
            Editable = false;
            OptionCaption = 'New,Cancellation,Correction';
            OptionMembers = New,Cancellation,Correction;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(32; "Related Line No."; Integer)
        {
            Caption = 'Related Line No.';
            Editable = false;
        }
        field(33; "Trade Role Type"; Option)
        {
            Caption = 'Trade Role Type';
            Editable = false;
            OptionCaption = 'Direct Trade,Intermediate Trade,Property Movement';
            OptionMembers = "Direct Trade","Intermediate Trade","Property Movement";

            trigger OnValidate()
            begin
                TestStatusOpen();
                CheckLineType();
            end;
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
        field(50; "Corrected Reg. No."; Boolean)
        {
            Caption = 'Corrected Reg. No.';
            Editable = false;
        }
        field(51; "Corrected Amount"; Boolean)
        {
            Caption = 'Corrected Amount';
            Editable = false;
        }
        field(54; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen();
                CheckLineType();
            end;
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
        field(99; "System-Created"; Boolean)
        {
            Caption = 'System-Created';
            Editable = false;
        }
        /// <summary>
        /// Unique record identifier for tracking and reference purposes in the VAT report.
        /// </summary>
        field(100; "Record Identifier"; Code[30])
        {
            Caption = 'Record Identifier';
            Editable = false;
        }
        field(101; "VAT Report to Correct"; Code[20])
        {
            Caption = 'VAT Report to Correct';
        }
        field(102; "Able to Correct Line"; Boolean)
        {
            Caption = 'Able to Correct Line';
        }
    }

    keys
    {
        key(Key1; "VAT Report No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Trade Type", "Country/Region Code", "VAT Registration No.", "Registration No.", "EU 3-Party Trade")
        {
        }
        key(Key3; "VAT Report to Correct", "Able to Correct Line")
        {
        }
        key(Key4; "VAT Report No.", "Line Type")
        {
            SumIndexFields = Base, Amount, "Number of Supplies";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        CheckEditingAllowed();

        VATReportLineRelation.Reset();
        VATReportLineRelation.SetRange("VAT Report No.", "VAT Report No.");
        VATReportLineRelation.SetRange("VAT Report Line No.", "Line No.");
        VATReportLineRelation.DeleteAll();
    end;

    trigger OnInsert()
    begin
        VATReportHeader.Get("VAT Report No.");
        if VATReportHeader."Original Report No." = '' then
            Validate("VAT Report to Correct", VATReportHeader."No.")
        else
            Validate("VAT Report to Correct", VATReportHeader."Original Report No.");
    end;

    trigger OnModify()
    begin
        CheckEditingAllowed();
    end;

    var
        VATReportHeader: Record "VAT Report Header";
        LineCannotBeEditedErr: Label 'Cancellation line cannot be changed.';
#pragma warning disable AA0470
        CorrectionEntryExistsErr: Label 'A correction entry already exists for this entry in report %1.';
#pragma warning restore AA0470

    local procedure TestStatusOpen()
    begin
        VATReportHeader.Get("VAT Report No.");
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
    end;

    [Scope('OnPrem')]
    procedure GetTradeRole(): Code[10]
    begin
        case "Trade Role Type" of
            "Trade Role Type"::"Direct Trade":
                case "Trade Type" of
                    "Trade Type"::Sale:
                        exit('0');
                    "Trade Type"::Purchase:
                        exit('0');
                end;
            "Trade Role Type"::"Property Movement":
                exit('1');
            "Trade Role Type"::"Intermediate Trade":
                exit('2');
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCancelCode(): Code[10]
    begin
        if "Line Type" = "Line Type"::Cancellation then
            exit('1');

        exit('0');
    end;

    [Scope('OnPrem')]
    procedure GetNextLineNo(VATReportNo: Code[20]): Integer
    var
        VATReportLine2: Record "VAT Report Line";
    begin
        VATReportLine2.SetRange("VAT Report No.", VATReportNo);
        if VATReportLine2.FindLast() then
            exit(VATReportLine2."Line No." + 10000);

        exit(10000);
    end;

    [Scope('OnPrem')]
    procedure RoundBase(AmountToRound: Decimal): Decimal
    begin
        exit(Round(AmountToRound, 1));
    end;

    [Scope('OnPrem')]
    procedure CheckLineType()
    begin
        if "Line Type" = "Line Type"::Cancellation then
            Error(LineCannotBeEditedErr);
    end;

    [Scope('OnPrem')]
    procedure CheckEditingAllowed()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportHeader.Get("VAT Report No.");
        VATReportHeader.CheckEditingAllowed();
    end;

    [Scope('OnPrem')]
    procedure InsertCorrLine(VATReportHeader: Record "VAT Report Header"; CancellationVATReportLine: Record "VAT Report Line"; CorrectionVATReportLine: Record "VAT Report Line"; var TempVATReportLineRelation: Record "VAT Report Line Relation" temporary)
    var
        VATReportLine2: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
        CancellationLineNo: Integer;
    begin
        CheckLineAlreadyCorrected(VATReportHeader, CorrectionVATReportLine);
        VATReportLine2.Init();
        VATReportLine2."VAT Report No." := VATReportHeader."No.";
        VATReportLine2."Line No." := VATReportLine2.GetNextLineNo(VATReportHeader."No.");
        VATReportLine2."Trade Type" := CancellationVATReportLine."Trade Type";
        VATReportLine2."Line Type" := VATReportLine2."Line Type"::Cancellation;
        VATReportLine2."Related Line No." := CancellationVATReportLine."Line No.";
        VATReportLine2."Country/Region Code" := CancellationVATReportLine."Country/Region Code";
        VATReportLine2."VAT Registration No." := CancellationVATReportLine."VAT Registration No.";
        VATReportLine2."EU 3-Party Trade" := CancellationVATReportLine."EU 3-Party Trade";
        VATReportLine2."EU Service" := CancellationVATReportLine."EU Service";
        VATReportLine2."Trade Role Type" := CancellationVATReportLine."Trade Role Type";
        VATReportLine2."Number of Supplies" := CancellationVATReportLine."Number of Supplies";
        VATReportLine2.Base := -CancellationVATReportLine.Base;
        VATReportLine2.Amount := -CancellationVATReportLine.Amount;
        VATReportLine2."System-Created" := true;
        VATReportLine2.Insert(true);
        CancellationLineNo := VATReportLine2."Line No.";

        VATReportLine2.Init();
        VATReportLine2."VAT Report No." := VATReportHeader."No.";
        VATReportLine2."Line No." += 10000;
        VATReportLine2."Trade Type" := CorrectionVATReportLine."Trade Type";
        VATReportLine2."Line Type" := VATReportLine2."Line Type"::Correction;
        VATReportLine2."Related Line No." := CorrectionVATReportLine."Line No.";
        VATReportLine2."Country/Region Code" := CorrectionVATReportLine."Country/Region Code";
        VATReportLine2."VAT Registration No." := CorrectionVATReportLine."VAT Registration No.";
        VATReportLine2."EU 3-Party Trade" := CorrectionVATReportLine."EU 3-Party Trade";
        VATReportLine2."EU Service" := CorrectionVATReportLine."EU Service";
        VATReportLine2."Trade Role Type" := CorrectionVATReportLine."Trade Role Type";
        VATReportLine2."Number of Supplies" := CorrectionVATReportLine."Number of Supplies";
        VATReportLine2.Base := VATReportLine2.RoundBase(CorrectionVATReportLine.Base);
        VATReportLine2.Amount := VATReportLine2.RoundBase(CorrectionVATReportLine.Amount);
        VATReportLine2."System-Created" := true;
        VATReportLine2.Insert(true);

        TempVATReportLineRelation.SetRange("VAT Report No.", VATReportLine2."VAT Report No.");
        TempVATReportLineRelation.SetRange("VAT Report Line No.", CorrectionVATReportLine."Line No.");
        if TempVATReportLineRelation.FindSet() then
            repeat
                VATReportLineRelation := TempVATReportLineRelation;
                VATReportLineRelation."VAT Report Line No." := VATReportLine2."Line No.";
                VATReportLineRelation.Insert();
                VATReportLineRelation."VAT Report Line No." := CancellationLineNo;
                VATReportLineRelation.Insert();
            until TempVATReportLineRelation.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckLineAlreadyCorrected(VATReportHeader: Record "VAT Report Header"; VATReportLine: Record "VAT Report Line")
    var
        VATReportLine1: Record "VAT Report Line";
    begin
        VATReportLine1.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine1.SetRange("VAT Registration No.", VATReportLine."VAT Registration No.");
        VATReportLine1.SetRange("Country/Region Code", VATReportLine."Country/Region Code");
        VATReportLine1.SetRange("Registration No.", VATReportLine."Registration No.");
        VATReportLine1.SetRange("Trade Role Type", VATReportLine."Trade Role Type");
        VATReportLine1.SetRange("EU 3-Party Trade", VATReportLine."EU 3-Party Trade");
        VATReportLine1.SetRange("EU Service", VATReportLine."EU Service");
        if VATReportLine1.FindFirst() then
            Error(CorrectionEntryExistsErr, VATReportHeader."No.");
    end;
}
