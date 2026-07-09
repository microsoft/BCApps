// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Single instance state that describes the stability preset combination currently being executed.
/// The orchestrator (codeunit "Stability Test Mgt") activates it before running a generated suite,
/// the event subscribers read it while tests run, and it is cleared once the combination completes.
/// </summary>
codeunit 130468 "Stability Context"
{
    SingleInstance = true;
    Access = Internal;

    var
        IsActiveState: Boolean;
        BaseSuiteName: Code[10];
        GeneratedSuiteName: Code[10];
        CombinationText: Text[250];
        SeedValue: Integer;
        SeedOverriddenState: Boolean;
        WorkDateOffsetText: Text[30];
        BaseWorkDateValue: Date;
        ReverseCodeunitsState: Boolean;
        ReverseMethodsState: Boolean;
        OneByOneState: Boolean;

    procedure Activate(NewBaseSuite: Code[10]; NewGeneratedSuite: Code[10]; NewCombination: Text[250])
    begin
        Clear(SeedValue);
        Clear(SeedOverriddenState);
        Clear(WorkDateOffsetText);
        Clear(ReverseCodeunitsState);
        Clear(ReverseMethodsState);
        Clear(OneByOneState);
        BaseSuiteName := NewBaseSuite;
        GeneratedSuiteName := NewGeneratedSuite;
        CombinationText := NewCombination;
        BaseWorkDateValue := WorkDate();
        IsActiveState := true;
    end;

    procedure Deactivate()
    begin
        IsActiveState := false;
    end;

    procedure IsActive(): Boolean
    begin
        exit(IsActiveState);
    end;

    procedure BaseSuite(): Code[10]
    begin
        exit(BaseSuiteName);
    end;

    procedure GeneratedSuite(): Code[10]
    begin
        exit(GeneratedSuiteName);
    end;

    procedure Combination(): Text[250]
    begin
        exit(CombinationText);
    end;

    procedure SetSeed(NewSeed: Integer)
    begin
        SeedValue := NewSeed;
        SeedOverriddenState := true;
    end;

    procedure Seed(): Integer
    begin
        exit(SeedValue);
    end;

    procedure IsSeedOverridden(): Boolean
    begin
        exit(SeedOverriddenState);
    end;

    procedure SetWorkDateOffset(NewOffset: Text[30])
    begin
        WorkDateOffsetText := NewOffset;
    end;

    procedure WorkDateOffset(): Text[30]
    begin
        exit(WorkDateOffsetText);
    end;

    procedure BaseWorkDate(): Date
    begin
        exit(BaseWorkDateValue);
    end;

    procedure SetReverseCodeunits(NewValue: Boolean)
    begin
        ReverseCodeunitsState := NewValue;
    end;

    procedure ReverseCodeunits(): Boolean
    begin
        exit(ReverseCodeunitsState);
    end;

    procedure SetReverseMethods(NewValue: Boolean)
    begin
        ReverseMethodsState := NewValue;
    end;

    procedure ReverseMethods(): Boolean
    begin
        exit(ReverseMethodsState);
    end;

    procedure SetOneByOne(NewValue: Boolean)
    begin
        OneByOneState := NewValue;
    end;

    procedure OneByOne(): Boolean
    begin
        exit(OneByOneState);
    end;
}
