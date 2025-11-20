// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

table 595 "Exch. Rate Adjmt. Buffer"
{
    Caption = 'Exch. Rate Adjmt. Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group ID"; Guid)
        {
            Caption = 'Group ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(3; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = SystemMetadata;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(7; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = SystemMetadata;
        }
        field(8; Index; Integer)
        {
            Caption = 'Index';
            DataClassification = SystemMetadata;
        }
        field(9; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Adjmt. Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'AdjBase';
            DataClassification = SystemMetadata;
        }
        field(11; "Adjmt. Base (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Adjmt. Base (LCY)';
            DataClassification = SystemMetadata;
        }
        field(12; "Adjmt. Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Adjmt. Amount';
            DataClassification = SystemMetadata;
        }
        field(13; "Gains Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Gains Amount';
            DataClassification = SystemMetadata;
        }
        field(14; "Losses Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Losses Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Group ID")
        {
            Clustered = true;
        }
        key(Key2; "Currency Code", "Posting Group", "Account No.", "Dimension Entry No.", "Posting Date", "IC Partner Code")
        {
        }
    }

    fieldgroups
    {
    }

    procedure BuildPrimaryKey()
    begin
        "Group ID" := CreateGuid();

        OnAfterBuildPrimaryKey(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildPrimaryKey(var ExchRateAdjmtBuffer: Record "Exch. Rate Adjmt. Buffer")
    begin
    end;
}
