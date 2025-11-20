// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Setup;

table 2151 "Upd Analysis View Entry Buffer"
{
    TableType = Temporary;

    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; AccNo; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(3; BusUnitCode; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(4; CashFlowForecastNo; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(5; DimValue1; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(6; DimValue2; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(7; DimValue3; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(8; DimValue4; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(9; PostingDate; Date)
        {
            DataClassification = CustomerContent;
        }
        field(10; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        field(11; DebitAmount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        field(12; CreditAmount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        field(13; AmountACY; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        field(14; DebitAmountACY; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        field(15; CreditAmountACY; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        field(16; EntryNo; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(17; "Account Source"; Enum "Analysis Account Source")
        {
            Caption = 'Account Source';
        }
    }
    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if GLSetup.Get() then
            exit(GLSetup."Additional Reporting Currency");
    end;
}
