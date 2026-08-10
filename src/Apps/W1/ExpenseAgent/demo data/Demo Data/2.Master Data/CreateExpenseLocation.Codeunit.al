// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Foundation;

codeunit 8208 "Create Expense Location"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        CreateCountryRegion: Codeunit "Create Country/Region";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseLocation(CanadaAll(), CanadaAllLocationLbl, CreateCountryRegion.CA(), '', '');
        ContosoExpenseAgent.InsertExpenseLocation(DenmarkAll(), DenmarkLbl, CreateCountryRegion.DK(), '', '');
        ContosoExpenseAgent.InsertExpenseLocation(Domestic(), DomesticLbl, '', '', '');
        ContosoExpenseAgent.InsertExpenseLocation(FranceAll(), FranceLbl, CreateCountryRegion.FR(), '', '');
        ContosoExpenseAgent.InsertExpenseLocation(GermanyAll(), GermanyLbl, CreateCountryRegion.DE(), '', '');
        ContosoExpenseAgent.InsertExpenseLocation(UKLondon(), UKLondonAreaLbl, CreateCountryRegion.GB(), LondonLbl, '');
        ContosoExpenseAgent.InsertExpenseLocation(UKOther(), UKOtherLbl, CreateCountryRegion.GB(), '', '');
        ContosoExpenseAgent.InsertExpenseLocation(USAFlorida(), USAFloridaLbl, CreateCountryRegion.US(), '', FLLbl);
        ContosoExpenseAgent.InsertExpenseLocation(USANY(), USANYLbl, CreateCountryRegion.US(), NewYorkLbl, '');
        ContosoExpenseAgent.InsertExpenseLocation(USAOther(), USAOtherLbl, CreateCountryRegion.US(), '', '');
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
        CanadaAllLocationLbl: Label 'Canada - all location', MaxLength = 100;
        DenmarkLbl: Label 'Denmark', MaxLength = 100;
        DomesticLbl: Label 'Domestic', MaxLength = 100;
        FranceLbl: Label 'France', MaxLength = 100;
        GermanyLbl: Label 'Germany', MaxLength = 100;
        UKLondonAreaLbl: Label 'United Kingdom - London area', MaxLength = 100;
        LondonLbl: Label 'London', MaxLength = 30;
        UKOtherLbl: Label 'United Kingdom - other', MaxLength = 100;
        USAFloridaLbl: Label 'United States - Florida', MaxLength = 100;
        USANYLbl: Label 'United States - New York', MaxLength = 100;
        USAOtherLbl: Label 'United States - Other', MaxLength = 100;
        NewYorkLbl: Label 'New York', MaxLength = 30;
        FLLbl: Label 'FL', MaxLength = 30;

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