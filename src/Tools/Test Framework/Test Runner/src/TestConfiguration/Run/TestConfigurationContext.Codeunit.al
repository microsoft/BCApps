// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Shared, single instance state for the configuration that is currently running. Providers write
/// their intent here during Prepare; the orchestrator and the runner read it while the base suite
/// runs. Everything is a no-op unless a configuration is active, so regular test runs are unaffected.
/// </summary>
codeunit 130469 "Test Configuration Context"
{
    SingleInstance = true;

    var
        ContextActive: Boolean;
        ActiveConfigCode: Code[20];
        ActiveBaseSuite: Code[10];
        DoReverseOrder: Boolean;
        DoOneByOne: Boolean;
        SeedValue: Integer;
        SeedIsSet: Boolean;
        WorkDateShifted: Boolean;
        WorkDateFormulaText: Text[30];
        CapturedBaseWorkDate: Date;

    /// <summary>
    /// Activates the context for a configuration run and resets all provider intent.
    /// </summary>
    /// <param name="BaseSuiteName">The base suite being exercised.</param>
    /// <param name="ConfigCode">The code of the configuration being applied.</param>
    procedure Activate(BaseSuiteName: Code[10]; ConfigCode: Code[20])
    begin
        ContextActive := true;
        ActiveBaseSuite := BaseSuiteName;
        ActiveConfigCode := ConfigCode;
        DoReverseOrder := false;
        DoOneByOne := false;
        SeedValue := 0;
        SeedIsSet := false;
        WorkDateShifted := false;
        WorkDateFormulaText := '';
        CapturedBaseWorkDate := WorkDate();
    end;

    /// <summary>
    /// Deactivates the context so subscribers become no-ops again.
    /// </summary>
    procedure Deactivate()
    begin
        ContextActive := false;
    end;

    procedure IsActive(): Boolean
    begin
        exit(ContextActive);
    end;

    procedure ConfigCode(): Code[20]
    begin
        exit(ActiveConfigCode);
    end;

    procedure BaseSuite(): Code[10]
    begin
        exit(ActiveBaseSuite);
    end;

    procedure SetReverseOrder(NewValue: Boolean)
    begin
        DoReverseOrder := NewValue;
    end;

    procedure ReverseOrder(): Boolean
    begin
        exit(DoReverseOrder);
    end;

    procedure SetOneByOne(NewValue: Boolean)
    begin
        DoOneByOne := NewValue;
    end;

    procedure OneByOne(): Boolean
    begin
        exit(DoOneByOne);
    end;

    procedure SetSeed(NewSeed: Integer)
    begin
        SeedValue := NewSeed;
        SeedIsSet := true;
    end;

    procedure IsSeedSet(): Boolean
    begin
        exit(SeedIsSet);
    end;

    procedure Seed(): Integer
    begin
        exit(SeedValue);
    end;

    procedure SetWorkDateFormula(FormulaText: Text[30])
    begin
        WorkDateFormulaText := FormulaText;
        WorkDateShifted := FormulaText <> '';
    end;

    procedure IsWorkDateShifted(): Boolean
    begin
        exit(WorkDateShifted);
    end;

    procedure WorkDateFormula(): Text[30]
    begin
        exit(WorkDateFormulaText);
    end;

    /// <summary>
    /// Returns the base WorkDate shifted by the configured formula, or the base WorkDate when no
    /// shift is configured.
    /// </summary>
    /// <returns>The WorkDate to use.</returns>
    procedure GetShiftedWorkDate(): Date
    var
        WorkDateFormula: DateFormula;
    begin
        if not WorkDateShifted then
            exit(CapturedBaseWorkDate);
        Evaluate(WorkDateFormula, WorkDateFormulaText);
        exit(CalcDate(WorkDateFormula, CapturedBaseWorkDate));
    end;
}
