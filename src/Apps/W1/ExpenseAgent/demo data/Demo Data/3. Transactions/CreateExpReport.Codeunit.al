// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoTool.Helpers;

codeunit 8218 "Create Exp. Report"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        CreateOpenExpenseReport();

        CreateReleasedExpenseReport();
    end;

    local procedure CreateOpenExpenseReport()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        CreateCurrency: Codeunit "Create Currency";
    begin
        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.JO(), ContosoUtility.AdjustDate(19030104D), ContosoUtility.AdjustDate(19030104D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.GroundTransportation(), '', TaxiDriveToClientLocationLbl, '', ContosoUtility.AdjustDate(19021218D), '', 32, TailwindTradersLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'Y68478567654', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Gifts(), '', CorporateGiftForBellowsCollegeLbl, '', ContosoUtility.AdjustDate(19021230D), '', 45, TailspinToysLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', '555666904', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);

        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.MH(), ContosoUtility.AdjustDate(19030104D), ContosoUtility.AdjustDate(19030104D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.MH(), CreateExpCategories.GroundTransportation(), '', TaxiDriveToClientLocationLbl, '', ContosoUtility.AdjustDate(19021223D), '', 17.55, TailwindTradersLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'KE634575675', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);

        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.RB(), ContosoUtility.AdjustDate(19030104D), ContosoUtility.AdjustDate(19030104D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.RB(), CreateExpCategories.GroundTransportation(), '', TaxiDriveToClientLocationLbl, '', ContosoUtility.AdjustDate(19021223D), '', 54, TailwindTradersLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'I674568543666', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);

        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.TD(), ContosoUtility.AdjustDate(19030104D), ContosoUtility.AdjustDate(19030104D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.TD(), CreateExpCategories.GroundTransportation(), '', TaxiDriveToClientLocationLbl, '', ContosoUtility.AdjustDate(19021223D), '', 26, TailwindTradersLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'D745676574568', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);

        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.JO(), ContosoUtility.AdjustDate(19030124D), ContosoUtility.AdjustDate(19030204D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Airline(), '', FlightTicketNYDCLbl, '', ContosoUtility.AdjustDate(19030107D), '', 380, MargieTravelLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'FGH7EJ', 'PR00010', '240');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.RentalCars(), '', CarRentalsForBusinessTravelLbl, '', ContosoUtility.AdjustDate(19030114D), CreateCurrency.EUR(), 721, FabrikamIncLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'UJ45436-457456-LP024', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
    end;

    local procedure CreateReleasedExpenseReport()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.LT(), ContosoUtility.AdjustDate(19030104D), ContosoUtility.AdjustDate(19030104D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.LT(), CreateExpCategories.Courier(), '', OrderedBooksLbl, '', ContosoUtility.AdjustDate(19021216D), '', 18, TailwindTradersLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', '67KK7556007UIP3460', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.LT(), CreateExpCategories.GroundTransportation(), '', TaxiDriveToClientLocationLbl, '', ContosoUtility.AdjustDate(19021216D), '', 23, TailwindTradersLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'G45347567', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.LT(), CreateExpCategories.Pharmacy(), '', PharmacyExpenseForHealthNeedsLbl, InjuryWhileWorkingOnProjectLbl, ContosoUtility.AdjustDate(19021223D), '', 35, ContosoPharmaceuticalsLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'TY46543576576755', 'PR00020', '1000');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.LT(), CreateExpCategories.GroundTransportation(), '', TaxiDriveToClientLocationLbl, '', ContosoUtility.AdjustDate(19021223D), '', 39.2, TailwindTradersLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'VB65864578548', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        ReleaseExpenseReport(ExpenseReportHeader);

        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser."OF"(), ContosoUtility.AdjustDate(19030104D), ContosoUtility.AdjustDate(19030104D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser."OF"(), CreateExpCategories.GroundTransportation(), '', TaxiDriveToClientLocationLbl, '', ContosoUtility.AdjustDate(19021226D), '', 28.6, TailwindTradersLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'HYC67567555678', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        ReleaseExpenseReport(ExpenseReportHeader);
    end;

    var
        ContosoUtility: Codeunit "Contoso Utilities";
        CreateExpenseUser: Codeunit "Create Expense User";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateExpCategories: Codeunit "Create Expense Categories DM";
        CreateExpensePaymentMethod: Codeunit "Create Expense Payment Method";
        CorporateGiftForBellowsCollegeLbl: Label 'Corporate gift for Bellows College', MaxLength = 100;
        TailspinToysLbl: Label 'Tailspin Toys', MaxLength = 100;
        FlightTicketNYDCLbl: Label 'Flight ticket NY/DC/NY', MaxLength = 100;
        CarRentalsForBusinessTravelLbl: Label 'Rental car for business travel', MaxLength = 100;
        FabrikamIncLbl: Label 'Fabrikam, Inc.', MaxLength = 100;
        OrderedBooksLbl: Label 'Ordered books', MaxLength = 100;
        PharmacyExpenseForHealthNeedsLbl: Label 'Pharmacy expense for health needs', MaxLength = 100;
        InjuryWhileWorkingOnProjectLbl: Label 'Injury while working on a project', MaxLength = 100;
        ContosoPharmaceuticalsLbl: Label 'Contoso Pharmaceuticals', MaxLength = 100;
        MargieTravelLbl: Label 'Margie''s Travel', MaxLength = 100;
        TailwindTradersLbl: Label 'Tailwind Traders', MaxLength = 100;
        TaxiDriveToClientLocationLbl: Label 'Taxi drive to the client location', MaxLength = 100;

    local procedure ReleaseAndAddExpenseToExpenseReport(Expense: Record Expense; ExpenseReportHeader: Record "Expense Report Header")
    var
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        ReleaseExpenseDocument.Run(Expense);

        CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
    end;

    local procedure ReleaseExpenseReport(ExpenseReportHeader: Record "Expense Report Header")
    var
        ReleaseExpenseReportDocument: Codeunit "Release Exp. Report Document";
    begin
        ReleaseExpenseReportDocument.Run(ExpenseReportHeader);
    end;
}