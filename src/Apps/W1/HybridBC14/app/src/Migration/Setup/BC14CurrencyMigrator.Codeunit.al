// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Finance.Currency;

codeunit 50193 "BC14 Currency Migrator" implements "ISetupMigrator"
{
    var
        MigratorNameLbl: Label 'Currency Migrator';

    procedure GetName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure Migrate(StopOnFirstError: Boolean): Boolean
    var
        BC14Currency: Record "BC14 Currency";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        Success: Boolean;
    begin
        Success := true;

        if not HasDataToMigrate() then
            exit(true);

        if BC14Currency.FindSet() then
            repeat
                if not TryMigrateCurrency(BC14Currency) then begin
                    BC14MigrationErrorHandler.LogError(GetName(), Database::"BC14 Currency", 'BC14 Currency', BC14Currency.Code, Database::Currency, GetLastErrorText(), BC14Currency.RecordId);
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                    ClearLastError();
                end;
            until BC14Currency.Next() = 0;

        exit(Success);
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14Currency: Record "BC14 Currency";
    begin
        exit(not BC14Currency.IsEmpty());
    end;

    [TryFunction]
    local procedure TryMigrateCurrency(BC14Currency: Record "BC14 Currency")
    var
        Currency: Record Currency;
    begin
        if Currency.Get(BC14Currency.Code) then begin
            TransferFields(BC14Currency, Currency);
            Currency.Modify(true);
        end else begin
            Currency.Init();
            TransferFields(BC14Currency, Currency);
            Currency.Insert(true);
        end;
    end;

    local procedure TransferFields(BC14Currency: Record "BC14 Currency"; var Currency: Record Currency)
    begin
        Currency.Code := BC14Currency.Code;
        Currency.Description := BC14Currency.Description;
        Currency."Unrealized Gains Acc." := BC14Currency."Unrealized Gains Acc.";
        Currency."Realized Gains Acc." := BC14Currency."Realized Gains Acc.";
        Currency."Unrealized Losses Acc." := BC14Currency."Unrealized Losses Acc.";
        Currency."Realized Losses Acc." := BC14Currency."Realized Losses Acc.";
        Currency."Invoice Rounding Precision" := BC14Currency."Invoice Rounding Precision";
        // Invoice Rounding Type: 0 = Nearest, 1 = Up, 2 = Down
        case BC14Currency."Invoice Rounding Type" of
            0:
                Currency."Invoice Rounding Type" := Currency."Invoice Rounding Type"::Nearest;
            1:
                Currency."Invoice Rounding Type" := Currency."Invoice Rounding Type"::Up;
            2:
                Currency."Invoice Rounding Type" := Currency."Invoice Rounding Type"::Down;
        end;
        Currency."Amount Rounding Precision" := BC14Currency."Amount Rounding Precision";
        Currency."Unit-Amount Rounding Precision" := BC14Currency."Unit-Amount Rounding Precision";
        Currency."Amount Decimal Places" := BC14Currency."Amount Decimal Places";
        Currency."Unit-Amount Decimal Places" := BC14Currency."Unit-Amount Decimal Places";
        Currency."Appln. Rounding Precision" := BC14Currency."Appln. Rounding Precision";
        Currency."EMU Currency" := BC14Currency."EMU Currency";
        Currency."Residual Gains Account" := BC14Currency."Residual Gains Account";
        Currency."Residual Losses Account" := BC14Currency."Residual Losses Account";
        Currency."Conv. LCY Rndg. Debit Acc." := BC14Currency."Conv. LCY Rndg. Debit Acc.";
        Currency."Conv. LCY Rndg. Credit Acc." := BC14Currency."Conv. LCY Rndg. Credit Acc.";
        Currency."Max. VAT Difference Allowed" := BC14Currency."Max. VAT Difference Allowed";
        // VAT Rounding Type: 0 = Nearest, 1 = Up, 2 = Down
        case BC14Currency."VAT Rounding Type" of
            0:
                Currency."VAT Rounding Type" := Currency."VAT Rounding Type"::Nearest;
            1:
                Currency."VAT Rounding Type" := Currency."VAT Rounding Type"::Up;
            2:
                Currency."VAT Rounding Type" := Currency."VAT Rounding Type"::Down;
        end;
        Currency.Symbol := BC14Currency.Symbol;
        Currency."ISO Code" := BC14Currency."ISO Code";
        Currency."ISO Numeric Code" := BC14Currency."ISO Numeric Code";

        // Allow extensions to map custom fields
        OnTransferCurrencyCustomFields(BC14Currency, Currency);
    end;

    /// <summary>
    /// Integration event raised during currency migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields from BC14 Currency to Currency.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferCurrencyCustomFields(BC14Currency: Record "BC14 Currency"; var Currency: Record Currency)
    begin
    end;
}
