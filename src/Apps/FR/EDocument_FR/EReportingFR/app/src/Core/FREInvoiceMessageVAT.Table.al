// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Finance.Currency;

table 10971 "FR E-Invoice Message VAT"
{
    Access = Internal;
    Caption = 'FR E-Invoice Message VAT';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = X;
    ReplicateData = false;

    fields
    {
        field(1; "Message Entry No."; Integer)
        {
            Caption = 'Message Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "FR E-Invoice Message"."Entry No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(3; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(4; "VAT Category Code"; Code[10])
        {
            Caption = 'VAT Category Code';
            DataClassification = CustomerContent;
        }
        field(5; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = CustomerContent;
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;
        }
    }

    keys
    {
        key(PK; "Message Entry No.", "Line No.")
        {
            Clustered = true;
        }
        key(VATBreakdown; "Message Entry No.", "VAT %", "VAT Category Code")
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
        ImmutableVATBreakdownErr: Label 'A French electronic invoice message VAT breakdown cannot be changed.';
}
