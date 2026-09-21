// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8208 "Create Expense Location"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"Create Expense Locations"); // in the expense app
    end;

    var
        CanadaAllTok: Label 'CANADA-ALL', MaxLength = 20, Locked = true;
        DenmarkAllTok: Label 'DENMARK-ALL', MaxLength = 20, Locked = true;
        DomesticTok: Label 'DOMESTIC', MaxLength = 20, Locked = true;
        FranceAllTok: Label 'FRANCE-ALL', MaxLength = 20, Locked = true;
        GermanyAllTok: Label 'GERMANY-ALL', MaxLength = 20, Locked = true;
        UKLondonTok: Label 'UK-LONDON', MaxLength = 20, Locked = true;
        UKOtherTok: Label 'UK-OTHER', MaxLength = 20, Locked = true;
        USAFloridaTok: Label 'USA-FLORIDA', MaxLength = 20, Locked = true;
        USANYTok: Label 'USA-NY', MaxLength = 20, Locked = true;
        USAOtherTok: Label 'USA-OTHER', MaxLength = 20, Locked = true;

    procedure CanadaAll(): Code[20]
    begin
        exit(CanadaAllTok);
    end;

    procedure DenmarkAll(): Code[20]
    begin
        exit(DenmarkAllTok);
    end;

    procedure Domestic(): Code[20]
    begin
        exit(DomesticTok);
    end;

    procedure FranceAll(): Code[20]
    begin
        exit(FranceAllTok);
    end;

    procedure GermanyAll(): Code[20]
    begin
        exit(GermanyAllTok);
    end;

    procedure UKLondon(): Code[20]
    begin
        exit(UKLondonTok);
    end;

    procedure UKOther(): Code[20]
    begin
        exit(UKOtherTok);
    end;

    procedure USAFlorida(): Code[20]
    begin
        exit(USAFloridaTok);
    end;

    procedure USANY(): Code[20]
    begin
        exit(USANYTok);
    end;

    procedure USAOther(): Code[20]
    begin
        exit(USAOtherTok);
    end;
}