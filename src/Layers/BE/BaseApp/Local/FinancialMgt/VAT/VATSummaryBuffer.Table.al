// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;

table 11303 "VAT Summary Buffer"
{
    Caption = 'VAT Summary Buffer';
    DrillDownPageID = "VAT Posting Setup";
    LookupPageID = "VAT Posting Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(2; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        field(3; "Base Invoices"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base Invoices';
            DataClassification = SystemMetadata;
        }
        field(4; "VAT Amount Invoices"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount Invoices';
            DataClassification = SystemMetadata;
        }
        field(5; "Add.-Curr. Base Invoices"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Add.-Curr. Base Invoices';
            DataClassification = SystemMetadata;
        }
        field(6; "Add.-Curr. VAT Amount Invoices"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. VAT Amount Invoices';
            DataClassification = SystemMetadata;
        }
        field(7; "Base CM"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base CM';
            DataClassification = SystemMetadata;
        }
        field(8; "VAT Amount CM"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount CM';
            DataClassification = SystemMetadata;
        }
        field(9; "Add.-Curr. Base CM"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Add.-Curr. Base CM';
            DataClassification = SystemMetadata;
        }
        field(10; "Add.-Curr. VAT Amount CM"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. VAT Amount CM';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "VAT Bus. Posting Group", "VAT Prod. Posting Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        GLSetupRead: Boolean;

    procedure InsertLine()
    var
        VATSumBuffer: Record "VAT Summary Buffer";
    begin
        VATSumBuffer := Rec;
        if Find() then begin
            "Base Invoices" := "Base Invoices" + VATSumBuffer."Base Invoices";
            "VAT Amount Invoices" := "VAT Amount Invoices" + VATSumBuffer."VAT Amount Invoices";
            "Add.-Curr. Base Invoices" := "Add.-Curr. Base Invoices" + VATSumBuffer."Add.-Curr. Base Invoices";
            "Add.-Curr. VAT Amount Invoices" := "Add.-Curr. VAT Amount Invoices" + VATSumBuffer."Add.-Curr. VAT Amount Invoices";
            "Base CM" := "Base CM" + VATSumBuffer."Base CM";
            "VAT Amount CM" := "VAT Amount CM" + VATSumBuffer."VAT Amount CM";
            "Add.-Curr. Base CM" := "Add.-Curr. Base CM" + VATSumBuffer."Add.-Curr. Base CM";
            "Add.-Curr. VAT Amount CM" := "Add.-Curr. VAT Amount CM" + VATSumBuffer."Add.-Curr. VAT Amount CM";
            Modify();
        end else
            Insert();
    end;

    procedure GetLine(Number: Integer)
    begin
        if Number = 1 then
            FindSet()
        else
            Next();
    end;

#if not CLEAN27
    [Obsolete('use GetAdditionalReportingCurrencyCode instead', '27.0')]
    procedure GetCurrencyCode(): Code[10]
    begin
        exit(GetAdditionalReportingCurrencyCode());
    end;
#endif
    procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;
}
