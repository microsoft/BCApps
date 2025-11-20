// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 362 "ECSL VAT Report Line"
{
    Caption = 'ECSL VAT Report Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Report No."; Code[20])
        {
            Caption = 'Report No.';
        }
        field(3; "Country Code"; Code[10])
        {
            Caption = 'Country Code';
        }
        field(4; "Customer VAT Reg. No."; Text[20])
        {
            Caption = 'Customer VAT Reg. No.';
        }
        field(5; "Total Value Of Supplies"; Decimal)
        {
            Caption = 'Total Value Of Supplies';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(6; "Transaction Indicator"; Option)
        {
            Caption = 'Transaction Indicator';
            OptionCaption = 'B2B Goods,,Triangulated Goods,B2B Services';
            OptionMembers = "B2B Goods",,"Triangulated Goods","B2B Services";
        }
    }

    keys
    {
        key(Key1; "Report No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ClearLines(VATReportHeader: Record "VAT Report Header")
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        ECSLVATReportLineRelation.SetRange("ECSL Report No.", VATReportHeader."No.");
        ECSLVATReportLineRelation.DeleteAll();
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.DeleteAll();
    end;
}
