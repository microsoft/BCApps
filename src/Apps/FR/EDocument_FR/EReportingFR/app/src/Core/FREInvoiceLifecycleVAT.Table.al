// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Finance.Currency;

table 10971 "FR E-Invoice Lifecycle VAT"
{
    Caption = 'FR E-Invoice Lifecycle VAT';
    DataClassification = CustomerContent;
    InherentPermissions = X;
    ReplicateData = false;

    fields
    {
        field(1; "Lifecycle Entry No."; Integer)
        {
            Caption = 'Lifecycle Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "FR E-Invoice Lifecycle"."Entry No.";
            ToolTip = 'Specifies the parent lifecycle occurrence entry.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the line number of the VAT breakdown entry.';
        }
        field(3; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the VAT rate for this breakdown line.';
        }
        field(4; "Reported Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Reported Amount';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the amount reported for this VAT rate.';
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency.Code;
            ToolTip = 'Specifies the currency of the reported VAT amount.';
        }
    }

    keys
    {
        key(PK; "Lifecycle Entry No.", "Line No.")
        {
            Clustered = true;
        }
        key(VATRate; "Lifecycle Entry No.", "VAT %")
        {
            Unique = true;
        }
    }

    trigger OnModify()
    begin
        Error(ImmutableVATBreakdownErr);
    end;

    trigger OnDelete()
    begin
        Error(ImmutableVATBreakdownErr);
    end;

    trigger OnRename()
    begin
        Error(ImmutableVATBreakdownErr);
    end;

    var
        ImmutableVATBreakdownErr: Label 'A French electronic invoice lifecycle VAT breakdown cannot be changed.';
}