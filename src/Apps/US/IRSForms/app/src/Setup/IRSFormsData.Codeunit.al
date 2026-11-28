// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using System.Reflection;

codeunit 10039 "IRS Forms Data"
{
    var
        Supplemental: Codeunit "IRS 1099 Supplemental";
        UnsupportedMsg: Label 'Supplemental boxes were not added because the target reporting period starts in %1 and ends in %2. Supplemental boxes are supported for tax years 2026 and later within a single calendar year.', Comment = '%1 = target starting year, %2 = target ending year';
        MissingFormMsg: Label 'Form %1 does not exist in this reporting period.', Comment = '%1 = form';
        MissingParentMsg: Label 'Parent form box %1 does not exist in this reporting period.', Comment = '%1 = parent form box';
        MappingMsg: Label 'The supplemental box number, parent form box, value type, or XML element does not meet the reporting requirements. Review the setup on the IRS 1099 Supplemental Boxes page.';
        BoxNoUsedByFormBoxMsg: Label 'The supplemental box number is already used by a form box.';
        StatementConflictMsg: Label '\\Company %1, period %2, statement row %3 has custom settings and was not changed. Review Value Source, Supplemental Box No., Description, Print with, and line order on the IRS 1099 Form Statement page.', Comment = '%1 = company, %2 = period, %3 = standard row';
        IncomeBoxConflictMsg: Label '\\Company %1, period %2, form box %3: the custom minimum reportable amount %4 was kept instead of the standard amount %5. Review Minimum Reportable Amount for this form box.', Comment = '%1 = company, %2 = period, %3 = box, %4 = custom minimum, %5 = standard minimum';
        SupplBoxConflictMsg: Label '\\Company %1, period %2, supplemental box %3 was not changed because its setup is customized or cannot be used for reporting. Review Parent Form Box No., Value Type, and XML Element Name on the IRS 1099 Supplemental Boxes page. Existing document lines were not changed.', Comment = '%1 = company, %2 = period, %3 = supplemental box';
        SupplBoxNumberConflictMsg: Label '\\Company %1, period %2, box number %3 is already used by a form box. The existing form box was not changed. Resolve the duplicate box number before setting up the supplemental box.', Comment = '%1 = company, %2 = period, %3 = box';
        SupplBoxParentMissingMsg: Label '\\Company %1, period %2, form %3, supplemental box %4 was not created because parent form box %5 does not exist. Create or correct the parent form box before setting up the supplemental box.', Comment = '%1 = company, %2 = period, %3 = form, %4 = supplemental box, %5 = parent form box';
        RecalculateMsg: Label '\\Company %1, period %2, document %3 with status Open (vendor %4, form %5) needs recalculation. Use Create Form Documents or Update Transmission and select the changes to apply. Existing documents and transmissions have not been changed.', Comment = '%1 = company, %2 = period, %3 = document ID, %4 = vendor, %5 = form';
        ParachuteTxt: Label 'Shows your total compensation of excess golden parachute payments subject to a 20% excise tax. See your tax return instructions for where to report.';
        ReservedTxt: Label 'Reserved for future use.';
        FatcaTxt: Label 'If the FATCA filing requirement box is checked, the payer is reporting on this Form 1099 to satisfy its account reporting requirement under chapter 4 of the Internal Revenue Code. You may also have a filing requirement. See the Instructions for Form 8938.';
        NecGeneralInstructionTxt: Label 'You received this form instead of Form W-2 because the payer did not consider you an employee and did not withhold income tax or social security and Medicare tax. If you believe you are an employee and cannot get the payer to correct this form, report the amount shown in box 1 on the line for “Wages, salaries, tips, etc.” of Form 1040, 1040-SR, or 1040-NR. You must also complete Form 8919 and attach it to your return. For more information, see Pub. 1779, Independent Contractor or Employee. If you are not an employee but the amount in box 1 is not self-employment (SE) income (for example, it is income from a sporadic activity or a hobby), report the amount shown in box 1 on the “Other income” line (on Schedule 1 (Form 1040)).', Locked = true;
        NecCompensationInstructionTxt: Label 'Shows nonemployee compensation. If the amount in this box is SE income, report it on Schedule C or F (Form 1040) if a sole proprietor, or on Form 1065 and Schedule K-1 (Form 1065) if a partnership, and the recipient/partner completes Schedule SE (Form 1040).', Locked = true;
        NecNoteInstructionTxt: Label 'If you are receiving payments on which no income, social security, and Medicare taxes are withheld, you should make estimated tax payments. See Form 1040-ES (or Form 1040-ES (NR)). Individuals must report these amounts as explained in these box 1 instructions. Corporations, fiduciaries, and partnerships must report these amounts on the appropriate line of their tax returns.', Locked = true;
        PreviousCashTipsTxt: Label 'Shows cash tips already included in the reported income. This is a breakdown, not additional income. Determine any deduction using the instructions for your tax return.';
        PreviousOccupationTxt: Label 'Shows up to two Treasury tipped occupation codes. Code 000 identifies a nonqualifying occupation and retains its leading zeros.';
        PreviousOvertimeTxt: Label 'Shows qualified overtime compensation already included in the reported income. Report only the qualified overtime premium portion, not all overtime pay. Determine any deduction using the instructions for your tax return.';
        CashTipsTxt: Label 'Shows the total amount of cash tips. “Cash tips” include tips received in cash or charged. This amount has been included in the amount reported in box %1. Use the amount in box %2 when determining the qualified tip deduction in Part II of Schedule 1-A (Form 1040).', Comment = '%1 = income box, %2 = cash tips box';
        OccupationTxt: Label 'Shows up to two Treasury Tipped Occupation Code(s) (TTOC) for your tipped occupation(s). Use this code(s) in determining the deduction for qualified tips in Part II of Schedule 1-A (Form 1040). If the occupation code 000 is used, and no other code is included in box %1, your cash tips are not qualified tips; do not use the amount reported in box %2 for the deduction for qualified tips.', Comment = '%1 = occupation codes box, %2 = cash tips box';
        OvertimeTxt: Label 'Shows the total amount of qualified overtime compensation. This amount has been included in the amount reported in box %1. Use the amount in box %2 when determining the qualified overtime compensation deduction in Part III of Schedule 1-A (Form 1040).', Comment = '%1 = income box, %2 = overtime compensation box';
        InstructionConflictMsg: Label '\\Company %1, period %2, form %3, instruction line %4 has custom text or ordering and was not changed. Review it on the IRS 1099 Form Instructions page.', Comment = '%1 = company, %2 = period, %3 = form, %4 = instruction line';
        IncorrectAnnualPeriodErr: Label 'Annual IRIS setup for period %1 in company %2 cannot be updated. %3 No setup changes were applied.', Comment = '%1 = period number, %2 = company, %3 = tax-year validation error';

    procedure AddReportingPeriodsWithForms(ReportingYear: Integer)
    var
        PeriodNo: Code[20];
        SetupDetails: Text;
    begin
        PeriodNo :=
            AddReportingPeriod(
                Format(ReportingYear),
                DMY2Date(1, 1, ReportingYear), DMY2Date(31, 12, ReportingYear), Format(ReportingYear));
        AddForm(PeriodNo, 'MISC', 'Miscellaneous Income');
        AddFormBox(PeriodNo, 'MISC', 'MISC-01', 'Rents', GetMinimumReportableAmount(ReportingYear, 600));
        AddFormBox(PeriodNo, 'MISC', 'MISC-02', 'Royalties', 10);
        AddFormBox(PeriodNo, 'MISC', 'MISC-03', 'Other Income', GetMinimumReportableAmount(ReportingYear, 600));
        AddFormBox(PeriodNo, 'MISC', 'MISC-04', 'Federal Income Tax Withheld', 0);
        AddFormBox(PeriodNo, 'MISC', 'MISC-05', 'Fishing Boat Proceeds', 600);
        AddFormBox(PeriodNo, 'MISC', 'MISC-06', 'Medical and Health Care Payments', GetMinimumReportableAmount(ReportingYear, 600));
        AddFormBox(PeriodNo, 'MISC', 'MISC-07', 'Payer made direct sales totaling $5,000 or more of consumer products to recipient for resale', 5000);
        AddFormBox(PeriodNo, 'MISC', 'MISC-08', 'Substitute Payments in Lieu of Dividends or Interest', 10);
        AddFormBox(PeriodNo, 'MISC', 'MISC-09', 'Crop Insurance Proceeds', GetMinimumReportableAmount(ReportingYear, 1));
        AddFormBox(PeriodNo, 'MISC', 'MISC-10', 'Gross Proceeds Paid to an Attorney', 0);
        AddFormBox(PeriodNo, 'MISC', 'MISC-11', 'Fish purchased for resale', 600);
        AddFormBox(PeriodNo, 'MISC', 'MISC-12', 'Section 409A deferrals', GetMinimumReportableAmount(ReportingYear, 600));
        AddFormBox(PeriodNo, 'MISC', 'MISC-15', 'Nonqualified deferred compensation', GetMinimumReportableAmount(ReportingYear, 0));
        AddFormBox(PeriodNo, 'MISC', 'MISC-16', 'State tax withheld', 0);
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-01', 10000, 'Rents');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-02', 20000, 'Royalties');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-03', 30000, 'Other Income');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-04', 40000, 'Federal Income Tax Withheld');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-05', 50000, 'Fishing Boat Proceeds');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-06', 60000, 'Medical and Health Care Payments');
        AddFormStatementLine(PeriodNo, 'MISC', Enum::"IRS 1099 Print Value Type"::"Yes/No", 'MISC-07', 70000, 'Payer made direct sales totaling $5,000 or more of consumer products to recipient for resale');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-08', 80000, 'Substitute Payments in Lieu of Dividends or Interest');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-09', 90000, 'Crop Insurance Proceeds');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-10', 100000, 'Gross Proceeds Paid to an Attorney');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-11', 110000, 'Fish purchased for resale');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-12', 120000, 'Section 409A deferrals');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-15', 140000, 'Nonqualified deferred compensation');
        AddFormStatementLine(PeriodNo, 'MISC', 'MISC-16', 150000, 'State tax withheld');

        AddForm(PeriodNo, 'NEC', 'Nonemployee Compensation');
        AddFormBox(PeriodNo, 'NEC', 'NEC-01', 'Nonemployee Compensation', GetMinimumReportableAmount(ReportingYear, 600));
        AddFormBox(PeriodNo, 'NEC', 'NEC-02', 'Payer made direct sales totaling $5,000 or more of consumer products to recipient for resale', 5000);
        AddFormBox(PeriodNo, 'NEC', 'NEC-03', 'Excess golden parachute payments', 0);
        AddFormBox(PeriodNo, 'NEC', 'NEC-04', 'Federal Income Tax Withheld', 0);
        AddFormStatementLine(PeriodNo, 'NEC', 'NEC-01', 10000, 'Nonemployee Compensation');
        AddFormStatementLine(PeriodNo, 'NEC', Enum::"IRS 1099 Print Value Type"::"Yes/No", 'NEC-02', 20000, 'Payer made direct sales totaling $5,000 or more of consumer products to recipient for resale');
        AddFormStatementLine(PeriodNo, 'NEC', 'NEC-03', 30000, 'Excess golden parachute payments');
        AddFormStatementLine(PeriodNo, 'NEC', 'NEC-04', 40000, 'Federal Income Tax Withheld');

        AddForm(PeriodNo, 'INT', 'Interest Income');
        AddFormBox(PeriodNo, 'INT', 'INT-01', 'Interest Income', 10);
        AddFormBox(PeriodNo, 'INT', 'INT-02', 'Early withdrawal penalty', -1);
        AddFormBox(PeriodNo, 'INT', 'INT-03', 'Interest on U.S. Savings Bonds and Treas. Obligations', 10);
        AddFormBox(PeriodNo, 'INT', 'INT-04', 'Federal Income Tax Withheld', -1);
        AddFormBox(PeriodNo, 'INT', 'INT-05', 'Investment Expenses', 10);
        AddFormBox(PeriodNo, 'INT', 'INT-06', 'Foreign Tax Paid', -1);
        AddFormBox(PeriodNo, 'INT', 'INT-08', 'Tax-Exempt Interest', 10);
        AddFormBox(PeriodNo, 'INT', 'INT-09', 'Specified Private Activity Bond Interest', 10);
        AddFormBox(PeriodNo, 'INT', 'INT-10', 'Market Discount', 10);
        AddFormBox(PeriodNo, 'INT', 'INT-11', 'Bond Premium', 0.01);
        AddFormBox(PeriodNo, 'INT', 'INT-12', 'Bond Premium on Treasury Obligations', 0.01);
        AddFormBox(PeriodNo, 'INT', 'INT-13', 'Bond Premium on Tax-Exempt Bond', 0.01);
        AddFormStatementLine(PeriodNo, 'INT', 'INT-01', 10000, 'Interest Income');
        AddFormStatementLine(PeriodNo, 'INT', 'INT-02', 20000, 'Early withdrawal penalty');
        AddFormStatementLine(PeriodNo, 'INT', 'INT-03', 30000, 'Interest on U.S. Savings Bonds and Treas. Obligations');
        AddFormStatementLine(PeriodNo, 'INT', 'INT-04', 40000, 'Federal Income Tax Withheld');
        AddFormStatementLine(PeriodNo, 'INT', 'INT-05', 50000, 'Investment Expenses');
        AddFormStatementLine(PeriodNo, 'INT', 'INT-06', 60000, 'Foreign Tax Paid');
        AddFormStatementLine(PeriodNo, 'INT', 'INT-08', 80000, 'Tax-Exempt Interest');
        AddFormStatementLine(PeriodNo, 'INT', 'INT-09', 90000, 'Specified Private Activity Bond Interest');
        AddFormStatementLine(PeriodNo, 'INT', 'INT-10', 100000, 'Market Discount');
        AddFormStatementLine(PeriodNo, 'INT', 'INT-11', 110000, 'Bond Premium');
        AddFormStatementLine(PeriodNo, 'INT', 'INT-12', 120000, 'Bond Premium on Treasury Obligations');
        AddFormStatementLine(PeriodNo, 'INT', 'INT-13', 130000, 'Bond Premium on Tax-Exempt Bond');

        AddForm(PeriodNo, 'DIV', 'Dividends and Distributions');
        AddFormBox(PeriodNo, 'DIV', 'DIV-01-A', 'Total Ordinary Dividends', 10);
        AddFormBox(PeriodNo, 'DIV', 'DIV-01-B', 'Qualified Dividends', 10);
        AddFormBox(PeriodNo, 'DIV', 'DIV-02-A', 'Total capital gain distr.', 0.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-02-B', 'Unrecap. Sec. 1250 gain', 10.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-02-C', 'Section 1202 gain', 0.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-02-D', 'Collectibles (28%) gain', 0.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-02-E', 'Section 897 ordinary dividends', 0.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-02-F', 'Section 897 capital gain', 0.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-03', 'Nondividend distributions', 10.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-04', 'Federal income tax withheld', -1.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-05', 'Section 199A dividends', 10.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-06', 'Investment expenses', 10.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-07', 'Foreign tax paid', -1.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-09', 'Cash liquidation distributions', 600.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-10', 'Noncash liquidation distributions', 600.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-12', 'Exempt-interest dividends', 0.0);
        AddFormBox(PeriodNo, 'DIV', 'DIV-13', 'Specified private activity bond interest dividends', 0.0);
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-01-A', 10000, 'Total Ordinary Dividends');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-01-B', 20000, 'Qualified Dividends');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-02-A', 30000, 'Total capital gain distr.');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-02-B', 40000, 'Unrecap. Sec. 1250 gain');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-02-C', 50000, 'Section 1202 gain');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-02-D', 60000, 'Collectibles (28%) gain');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-02-E', 70000, 'Section 897 ordinary dividends');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-02-F', 80000, 'Section 897 capital gain');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-03', 90000, 'Nondividend distributions');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-04', 100000, 'Federal income tax withheld');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-05', 110000, 'Section 199A dividends');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-06', 120000, 'Investment expenses');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-07', 130000, 'Foreign Tax Paid');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-09', 140000, 'Cash liquidation distributions');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-10', 150000, 'Noncash liquidation distributions');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-12', 160000, 'Exempt-interest dividends');
        AddFormStatementLine(PeriodNo, 'DIV', 'DIV-13', 170000, 'Specified private activity bond interest dividends');

        AddFormInstructionLines(PeriodNo);
        UpdateAnnualSetup(PeriodNo, CompanyName(), SetupDetails);
    end;

    internal procedure UpdateAnnualSetup(PeriodNo: Code[20]; TargetCompany: Text; var Details: Text)
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        ReportingPeriod.ChangeCompany(TargetCompany);
        ReportingPeriod.Get(PeriodNo);
        ValidatePeriodNoForSupplementalSetup(ReportingPeriod);
        AddFormBoxNumberConflictMessages(PeriodNo, TargetCompany, Details);
        UpdateAnnualBoxSetup(PeriodNo, TargetCompany, Details);
        UpdateAnnualInstructions(ReportingPeriod, TargetCompany, Details);
        if not SupportsSupplementalSetup(PeriodNo, TargetCompany) then
            exit;

        UpdateCompensationStatementLine(PeriodNo, TargetCompany, Details);
        UpdateSupplStatementLine(PeriodNo, TargetCompany, 'NEC', 'NEC-01B', 12500, 'Cash tips (box 1b)', Details);
        UpdateSupplStatementLine(PeriodNo, TargetCompany, 'NEC', 'NEC-01C', 15000, 'Treasury tipped occupation codes (box 1c)', Details);
        UpdateSupplStatementLine(PeriodNo, TargetCompany, 'NEC', 'NEC-01D', 17500, 'Qualified overtime compensation (box 1d)', Details);
        UpdateSupplStatementLine(PeriodNo, TargetCompany, 'MISC', 'MISC-13A', 125000, 'Cash tips (box 13a)', Details);
        UpdateSupplStatementLine(PeriodNo, TargetCompany, 'MISC', 'MISC-13B', 127500, 'Treasury tipped occupation codes (box 13b)', Details);
        UpdateSupplStatementLine(PeriodNo, TargetCompany, 'MISC', 'MISC-14', 130000, 'Qualified overtime compensation (box 14)', Details);
        AddRecalculationNotice(PeriodNo, TargetCompany, Details);
    end;

    internal procedure SupportsSupplementalSetup(PeriodNo: Code[20]; TargetCompany: Text): Boolean
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        ReportingPeriod.ChangeCompany(TargetCompany);
        ReportingPeriod.Get(PeriodNo);
        exit((Date2DMY(ReportingPeriod."Starting Date", 3) >= 2026) and
             (Date2DMY(ReportingPeriod."Ending Date", 3) = Date2DMY(ReportingPeriod."Starting Date", 3)));
    end;

    internal procedure UpdateAnnualBoxSetup(PeriodNo: Code[20]; TargetCompany: Text; var Details: Text)
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        if not SupportsSupplementalSetup(PeriodNo, TargetCompany) then
            exit;

        ReportingPeriod.ChangeCompany(TargetCompany);
        ReportingPeriod.Get(PeriodNo);
        ValidatePeriodNoForSupplementalSetup(ReportingPeriod);
        UpdateIncomeBox(PeriodNo, TargetCompany, 'MISC', 'MISC-01', 'Rents', 600, Details);
        UpdateIncomeBox(PeriodNo, TargetCompany, 'MISC', 'MISC-03', 'Other Income', 600, Details);
        UpdateIncomeBox(PeriodNo, TargetCompany, 'MISC', 'MISC-06', 'Medical and Health Care Payments', 600, Details);
        UpdateIncomeBox(PeriodNo, TargetCompany, 'MISC', 'MISC-09', 'Crop Insurance Proceeds', 1, Details);
        UpdateIncomeBox(PeriodNo, TargetCompany, 'MISC', 'MISC-12', 'Section 409A deferrals', 600, Details);
        UpdateIncomeBox(PeriodNo, TargetCompany, 'MISC', 'MISC-15', 'Nonqualified deferred compensation', 0, Details);
        UpdateIncomeBox(PeriodNo, TargetCompany, 'NEC', 'NEC-01', 'Nonemployee Compensation', 600, Details);
        UpdateSupplementalBox(PeriodNo, TargetCompany, 'NEC', 'NEC-01B', 'Cash tips (box 1b)', Details);
        UpdateSupplementalBox(PeriodNo, TargetCompany, 'NEC', 'NEC-01C', 'Treasury tipped occupation codes (box 1c)', Details);
        UpdateSupplementalBox(PeriodNo, TargetCompany, 'NEC', 'NEC-01D', 'Qualified overtime compensation (box 1d)', Details);
        UpdateSupplementalBox(PeriodNo, TargetCompany, 'MISC', 'MISC-13A', 'Cash tips (box 13a)', Details);
        UpdateSupplementalBox(PeriodNo, TargetCompany, 'MISC', 'MISC-13B', 'Treasury tipped occupation codes (box 13b)', Details);
        UpdateSupplementalBox(PeriodNo, TargetCompany, 'MISC', 'MISC-14', 'Qualified overtime compensation (box 14)', Details);
    end;

    internal procedure ValidatePeriodNoForSupplementalSetup(ReportingPeriod: Record "IRS Reporting Period")
    var
        HelperIRIS: Codeunit "Helper IRIS";
    begin
        if (Date2DMY(ReportingPeriod."Starting Date", 3) < 2026) or
           (Date2DMY(ReportingPeriod."Starting Date", 3) <> Date2DMY(ReportingPeriod."Ending Date", 3))
        then
            exit;
        if not HelperIRIS.ValidateTaxYear(ReportingPeriod."No.") then
            Error(IncorrectAnnualPeriodErr, ReportingPeriod."No.", ReportingPeriod.CurrentCompany(), GetLastErrorText());
    end;

    internal procedure GetUnsupportedSupplSetupReason(PeriodNo: Code[20]; TargetCompany: Text): Text
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        ReportingPeriod.ChangeCompany(TargetCompany);
        ReportingPeriod.Get(PeriodNo);
        exit(StrSubstNo(UnsupportedMsg, Format(Date2DMY(ReportingPeriod."Starting Date", 3), 0, 9), Format(Date2DMY(ReportingPeriod."Ending Date", 3), 0, 9)));
    end;

    internal procedure GetSupplBoxSetupConflictMessage(SupplBox: Record "IRS 1099 Suppl. Box"; TargetCompany: Text): Text
    var
        Form: Record "IRS 1099 Form";
        FormBox: Record "IRS 1099 Form Box";
        ParentBoxNo: Code[20];
        ElementName: Text[100];
        ValueType: Enum "IRS 1099 Supplemental Type";
    begin
        if not SupportsSupplementalSetup(SupplBox."Period No.", TargetCompany) then
            exit(GetUnsupportedSupplSetupReason(SupplBox."Period No.", TargetCompany));
        if not (SupplBox."Form No." in ['MISC', 'NEC']) or (SupplBox."No." = '') or
           (SupplBox."Parent Form Box No." = '')
        then
            exit(MappingMsg);
        Form.ChangeCompany(TargetCompany);
        if not Form.Get(SupplBox."Period No.", SupplBox."Form No.") then
            exit(StrSubstNo(MissingFormMsg, SupplBox."Form No."));
        FormBox.ChangeCompany(TargetCompany);
        if FormBox.Get(SupplBox."Period No.", SupplBox."Form No.", SupplBox."No.") then
            exit(BoxNoUsedByFormBoxMsg);
        if not FormBox.Get(SupplBox."Period No.", SupplBox."Form No.", SupplBox."Parent Form Box No.") then
            exit(StrSubstNo(MissingParentMsg, SupplBox."Parent Form Box No."));
        if FormBox.GetSupplBoxNoConflictMessage() <> '' then
            exit(FormBox.GetSupplBoxNoConflictMessage());
        if Supplemental.GetMapping(SupplBox."Period No.", SupplBox."Form No.", SupplBox."No.", ParentBoxNo, ElementName, ValueType) then begin
            if (SupplBox."Parent Form Box No." <> ParentBoxNo) or (SupplBox."Value Type" <> ValueType) or
               (SupplBox."XML Element Name" <> ElementName)
            then
                exit(MappingMsg);
        end else
            if (SupplBox."XML Element Name" <> '') or
               (SupplBox."No." in ['NEC-01B', 'NEC-01C', 'NEC-01D', 'MISC-13A', 'MISC-13B', 'MISC-14'])
            then
                exit(MappingMsg);
        exit('');
    end;

    local procedure AddFormBoxNumberConflictMessages(PeriodNo: Code[20]; TargetCompany: Text; var Details: Text)
    var
        FormBox: Record "IRS 1099 Form Box";
        Conflict: Text;
        DetailsBuilder: TextBuilder;
    begin
        DetailsBuilder.Append(Details);
        FormBox.ChangeCompany(TargetCompany);
        FormBox.SetRange("Period No.", PeriodNo);
        if FormBox.FindSet() then
            repeat
                Conflict := FormBox.GetSupplBoxNoConflictMessage();
                if Conflict <> '' then begin
                    DetailsBuilder.Append('\\');
                    DetailsBuilder.Append(Conflict);
                end;
            until FormBox.Next() = 0;
        Details := DetailsBuilder.ToText();
    end;

    local procedure UpdateCompensationStatementLine(PeriodNo: Code[20]; TargetCompany: Text; var Details: Text)
    var
        StatementLine: Record "IRS 1099 Form Statement Line";
        StandardLine: Record "IRS 1099 Form Statement Line";
        FormBox: Record "IRS 1099 Form Box";
        Description: Text[100];
    begin
        FormBox.ChangeCompany(TargetCompany);
        if not FormBox.Get(PeriodNo, 'NEC', 'NEC-01') then
            exit;
        Description := 'Nonemployee Compensation (box 1a)';
        StandardLine."Period No." := PeriodNo;
        StandardLine."Form No." := 'NEC';
        StandardLine."Line No." := 10000;
        StandardLine."Row No." := 'NEC-01';
        StandardLine.SetFormBoxFilter('NEC-01');
        StatementLine.ChangeCompany(TargetCompany);
        StatementLine.SetRange("Period No.", PeriodNo);
        StatementLine.SetRange("Form No.", 'NEC');
        StatementLine.SetRange("Row No.", 'NEC-01');
        if StatementLine.FindFirst() then begin
            if not HasStandardStatementSettings(StatementLine, StandardLine) or
               (StatementLine."Line No." <> StandardLine."Line No.") or
               not (StatementLine.Description in ['Nonemployee Compensation', Description])
            then begin
                AddStatementConflict(PeriodNo, TargetCompany, 'NEC-01', Details);
                exit;
            end;
            if StatementLine.Description <> Description then begin
                StatementLine.Description := Description;
                StatementLine.Modify();
            end;
            exit;
        end;
        if StatementLine.Get(PeriodNo, 'NEC', 10000) then begin
            AddStatementConflict(PeriodNo, TargetCompany, 'NEC-01', Details);
            exit;
        end;
        StatementLine := StandardLine;
        StatementLine.Description := Description;
        StatementLine.Insert();
    end;

    local procedure UpdateSupplStatementLine(PeriodNo: Code[20]; TargetCompany: Text; FormNo: Code[20]; BoxNo: Code[20]; DefaultLineNo: Integer; Description: Text[100]; var Details: Text)
    var
        SupplBox: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        StandardLine: Record "IRS 1099 Form Statement Line";
        ParentBoxNo: Code[20];
        ElementName: Text[100];
        ValueType: Enum "IRS 1099 Supplemental Type";
    begin
        SupplBox.ChangeCompany(TargetCompany);
        if not SupplBox.Get(PeriodNo, FormNo, BoxNo) then
            exit;
        if GetSupplBoxSetupConflictMessage(SupplBox, TargetCompany) <> '' then
            exit;
        FormBox.ChangeCompany(TargetCompany);
        if FormBox.Get(PeriodNo, FormNo, BoxNo) then
            exit;
        Supplemental.GetMapping(PeriodNo, FormNo, BoxNo, ParentBoxNo, ElementName, ValueType);
        if (SupplBox."Parent Form Box No." <> ParentBoxNo) or (SupplBox."XML Element Name" <> ElementName) or
           (SupplBox."Value Type" <> ValueType)
        then
            exit;
        StandardLine."Period No." := PeriodNo;
        StandardLine."Form No." := FormNo;
        StandardLine."Line No." := DefaultLineNo;
        StandardLine."Row No." := BoxNo;
        StandardLine.Description := Description;
        StandardLine."Value Source" := StandardLine."Value Source"::"Supplemental Line";
        StandardLine."Supplemental Box No." := BoxNo;
        StatementLine.ChangeCompany(TargetCompany);
        StatementLine.SetRange("Period No.", PeriodNo);
        StatementLine.SetRange("Form No.", FormNo);
        StatementLine.SetRange("Row No.", BoxNo);
        if StatementLine.FindFirst() then begin
            if not HasStandardStatementSettings(StatementLine, StandardLine) or
               (StatementLine.Description <> Description) or (StatementLine."Line No." <> DefaultLineNo)
            then
                AddStatementConflict(PeriodNo, TargetCompany, BoxNo, Details);
            exit;
        end;
        if StatementLine.Get(PeriodNo, FormNo, DefaultLineNo) then begin
            AddStatementConflict(PeriodNo, TargetCompany, BoxNo, Details);
            exit;
        end;
        StatementLine := StandardLine;
        StatementLine.ValidateSupplBox(TargetCompany);
        StatementLine.Insert();
    end;

    local procedure HasStandardStatementSettings(StatementLine: Record "IRS 1099 Form Statement Line"; StandardLine: Record "IRS 1099 Form Statement Line"): Boolean
    begin
        exit((StatementLine."Value Source" = StandardLine."Value Source") and
             (StatementLine."Supplemental Box No." = StandardLine."Supplemental Box No.") and
             (StatementLine."Record View String" = StandardLine."Record View String") and
             (StatementLine."Filter Expression" = StandardLine."Filter Expression") and
             (StatementLine."Print Value Type" = StandardLine."Print Value Type") and
             (StatementLine."Print with" = StandardLine."Print with") and
             (StatementLine."Row Totaling" = StandardLine."Row Totaling"));
    end;

    local procedure AddStatementConflict(PeriodNo: Code[20]; TargetCompany: Text; BoxNo: Code[20]; var Details: Text)
    begin
        Details += StrSubstNo(StatementConflictMsg, TargetCompany, PeriodNo, BoxNo);
    end;

    local procedure GetMinimumReportableAmount(ReportingYear: Integer; PreviousMinimum: Decimal): Decimal
    begin
        if ReportingYear >= 2026 then
            exit(2000);
        exit(PreviousMinimum);
    end;

    local procedure UpdateIncomeBox(PeriodNo: Code[20]; TargetCompany: Text; FormNo: Code[20]; BoxNo: Code[20]; Description: Text[250]; PreviousMinimum: Decimal; var Details: Text)
    var
        ReportingPeriod: Record "IRS Reporting Period";
        IRS1099Form: Record "IRS 1099 Form";
        FormBox: Record "IRS 1099 Form Box";
        MinimumAmount: Decimal;
        FormBoxConflictMessage: Text;
    begin
        IRS1099Form.ChangeCompany(TargetCompany);
        FormBox.ChangeCompany(TargetCompany);
        if not IRS1099Form.Get(PeriodNo, FormNo) then begin
            IRS1099Form.Init();
            IRS1099Form."Period No." := PeriodNo;
            IRS1099Form."No." := FormNo;
            IRS1099Form.Description := FormNo;
            IRS1099Form.Insert(true);
        end;
        ReportingPeriod.ChangeCompany(TargetCompany);
        ReportingPeriod.Get(PeriodNo);
        MinimumAmount := GetMinimumReportableAmount(Date2DMY(ReportingPeriod."Starting Date", 3), PreviousMinimum);
        if not FormBox.Get(PeriodNo, FormNo, BoxNo) then begin
            FormBox.Init();
            FormBox."Period No." := PeriodNo;
            FormBox."Form No." := FormNo;
            FormBox."No." := BoxNo;
            FormBox.Description := Description;
            FormBox."Minimum Reportable Amount" := MinimumAmount;
            FormBoxConflictMessage := FormBox.GetSupplBoxNoConflictMessage();
            if FormBoxConflictMessage <> '' then begin
                Details += '\\' + FormBoxConflictMessage;
                exit;
            end;
            FormBox.Insert(true);
            exit;
        end;
        if FormBox.GetSupplBoxNoConflictMessage() <> '' then
            exit;
        if FormBox."Minimum Reportable Amount" = MinimumAmount then
            exit;
        if FormBox."Minimum Reportable Amount" = PreviousMinimum then begin
            FormBox.Validate("Minimum Reportable Amount", MinimumAmount);
            FormBox.Modify(true);
        end else
            Details += StrSubstNo(IncomeBoxConflictMsg, TargetCompany, PeriodNo, BoxNo, FormBox."Minimum Reportable Amount", MinimumAmount);
    end;

    local procedure UpdateSupplementalBox(PeriodNo: Code[20]; TargetCompany: Text; FormNo: Code[20]; BoxNo: Code[20]; Description: Text[250]; var Details: Text)
    var
        SupplBox: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
        ParentBoxNo: Code[20];
        ElementName: Text[100];
        ValueType: Enum "IRS 1099 Supplemental Type";
        DependencyConflict: Text;
    begin
        Supplemental.GetMapping(PeriodNo, FormNo, BoxNo, ParentBoxNo, ElementName, ValueType);
        FormBox.ChangeCompany(TargetCompany);
        if FormBox.Get(PeriodNo, FormNo, BoxNo) then begin
            Details += StrSubstNo(SupplBoxNumberConflictMsg, TargetCompany, PeriodNo, BoxNo);
            exit;
        end;
        SupplBox.ChangeCompany(TargetCompany);
        if SupplBox.Get(PeriodNo, FormNo, BoxNo) then begin
            if (SupplBox."Parent Form Box No." <> ParentBoxNo) or (SupplBox."Value Type" <> ValueType) or
               (SupplBox."XML Element Name" <> ElementName)
            then
                Details += StrSubstNo(SupplBoxConflictMsg, TargetCompany, PeriodNo, BoxNo)
            else
                if GetSupplBoxSetupConflictMessage(SupplBox, TargetCompany) <> '' then
                    Details += StrSubstNo(SupplBoxConflictMsg, TargetCompany, PeriodNo, BoxNo);
            exit;
        end;
        if not FormBox.Get(PeriodNo, FormNo, ParentBoxNo) then begin
            Details += StrSubstNo(SupplBoxParentMissingMsg, TargetCompany, PeriodNo, FormNo, BoxNo, ParentBoxNo);
            exit;
        end;
        SupplBox.Init();
        SupplBox."Period No." := PeriodNo;
        SupplBox."Form No." := FormNo;
        SupplBox."No." := BoxNo;
        SupplBox.Description := Description;
        SupplBox."Parent Form Box No." := ParentBoxNo;
        SupplBox."Value Type" := ValueType;
        SupplBox."XML Element Name" := ElementName;
        DependencyConflict := GetSupplBoxSetupConflictMessage(SupplBox, TargetCompany);
        if DependencyConflict <> '' then begin
            Details += StrSubstNo(SupplBoxConflictMsg, TargetCompany, PeriodNo, BoxNo) + ' ' + DependencyConflict;
            exit;
        end;
        // ChangeCompany does not move table triggers into the target company.
        Supplemental.ValidateSupplBoxSetup(SupplBox, TargetCompany);
        SupplBox.Insert();
    end;

    local procedure AddRecalculationNotice(PeriodNo: Code[20]; TargetCompany: Text; var Details: Text)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        DocLine: Record "IRS 1099 Form Doc. Line";
        FormBox: Record "IRS 1099 Form Box";
        RequiresRecalculation: Boolean;
    begin
        DocHeader.ChangeCompany(TargetCompany);
        DocLine.ChangeCompany(TargetCompany);
        FormBox.ChangeCompany(TargetCompany);
        DocHeader.SetRange("Period No.", PeriodNo);
        DocHeader.SetRange(Status, DocHeader.Status::Open);
        if DocHeader.FindSet() then
            repeat
                RequiresRecalculation := false;
                DocLine.SetRange("Document ID", DocHeader.ID);
                DocLine.SetFilter("Form Box No.", 'MISC-01|MISC-03|MISC-06|MISC-09|MISC-12|MISC-15|NEC-01');
                if DocLine.FindSet() then
                    repeat
                        if FormBox.Get(PeriodNo, DocHeader."Form No.", DocLine."Form Box No.") then
                            RequiresRecalculation := RequiresRecalculation or
                                (DocLine."Minimum Reportable Amount" <> FormBox."Minimum Reportable Amount");
                    until DocLine.Next() = 0;
                if RequiresRecalculation then
                    Details += StrSubstNo(RecalculateMsg, TargetCompany, PeriodNo, DocHeader.ID, DocHeader."Vendor No.", DocHeader."Form No.");
            until DocHeader.Next() = 0;
    end;

    procedure AddFormInstructionLines(PeriodNo: Code[20])
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Details: Text;
    begin
        AddNecFormInstructionLines(PeriodNo);
        AddIntFormInstructionLines(PeriodNo);
        AddMiscFormInstructionLines(PeriodNo);
        AddDivFormInstructionLines(PeriodNo);
        ReportingPeriod.Get(PeriodNo);
        UpdateAnnualInstructions(ReportingPeriod, CompanyName(), Details);
    end;

    local procedure UpdateAnnualInstructions(ReportingPeriod: Record "IRS Reporting Period"; TargetCompany: Text; var Details: Text)
    var
        ReportingYear: Integer;
    begin
        ReportingYear := Date2DMY(ReportingPeriod."Starting Date", 3);
        if (ReportingYear < 2025) or (Date2DMY(ReportingPeriod."Ending Date", 3) <> ReportingYear) then
            exit;

        UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'NEC', 7, 'Box 3.', ReservedTxt, '', '', 'Box 3.', ParachuteTxt, Details);
        if ReportingYear = 2025 then begin
            UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'MISC', 18, 'Box 14.', ParachuteTxt, '', '', 'Box 14.', ReservedTxt, Details);
            exit;
        end;

        UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'NEC', 1, '', NecGeneralInstructionTxt, '', '', '', NecGeneralInstructionTxt.Replace('box 1', 'box 1a'), Details);
        UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'NEC', 4, 'Box 1.', NecCompensationInstructionTxt, '', '', 'Box 1a.', NecCompensationInstructionTxt, Details);
        UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'NEC', 5, 'Note:', NecNoteInstructionTxt, '', '', 'Note:', NecNoteInstructionTxt.Replace('box 1', 'box 1a'), Details);
        UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'NEC', 12, 'Box 1b.', PreviousCashTipsTxt, '', '', 'Box 1b.', StrSubstNo(CashTipsTxt, '1a', '1b'), Details);
        UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'NEC', 13, 'Box 1c.', PreviousOccupationTxt, '', '', 'Box 1c.', StrSubstNo(OccupationTxt, '1c', '1b'), Details);
        UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'NEC', 14, 'Box 1d.', PreviousOvertimeTxt, '', '', 'Box 1d.', StrSubstNo(OvertimeTxt, '1a', '1d'), Details);
        UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'MISC', 17, 'Box 13.', FatcaTxt, '', '', 'FATCA filing requirement.', FatcaTxt, Details);
        UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'MISC', 18, 'Box 14.', ParachuteTxt, ReservedTxt, PreviousOvertimeTxt, 'Box 14.', StrSubstNo(OvertimeTxt, '3', '14'), Details);
        UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'MISC', 23, 'Box 13a.', PreviousCashTipsTxt, '', '', 'Box 13a.', StrSubstNo(CashTipsTxt, '3', '13a'), Details);
        UpdateFormInstruction(ReportingPeriod."No.", TargetCompany, 'MISC', 24, 'Box 13b.', PreviousOccupationTxt, '', '', 'Box 13b.', StrSubstNo(OccupationTxt, '13b', '13a'), Details);
    end;

    local procedure UpdateFormInstruction(PeriodNo: Code[20]; TargetCompany: Text; FormNo: Code[20]; LineNo: Integer; PreviousHeader: Text; PreviousDescription: Text; EarlierDescription: Text; AdditionalPreviousDescription: Text; Header: Text; Description: Text; var Details: Text)
    var
        Form: Record "IRS 1099 Form";
        Instruction: Record "IRS 1099 Form Instruction";
    begin
        Form.ChangeCompany(TargetCompany);
        if not Form.Get(PeriodNo, FormNo) then
            exit;
        Instruction.ChangeCompany(TargetCompany);
        if Instruction.Get(PeriodNo, FormNo, LineNo) then begin
            if (Instruction.Header = Header) and (Instruction.Description = Description) then
                exit;
            if (Instruction.Header <> PreviousHeader) or
               ((Instruction.Description <> PreviousDescription) and
                ((EarlierDescription = '') or (Instruction.Description <> EarlierDescription)) and
                ((AdditionalPreviousDescription = '') or (Instruction.Description <> AdditionalPreviousDescription)))
            then begin
                Details += StrSubstNo(InstructionConflictMsg, TargetCompany, PeriodNo, FormNo, LineNo);
                exit;
            end;
        end else begin
            Instruction.SetRange("Period No.", PeriodNo);
            Instruction.SetRange("Form No.", FormNo);
            Instruction.SetFilter(Header, '%1|%2', Header, PreviousHeader);
            if not Instruction.IsEmpty() then begin
                Details += StrSubstNo(InstructionConflictMsg, TargetCompany, PeriodNo, FormNo, LineNo);
                exit;
            end;
            Instruction.Init();
            Instruction."Period No." := PeriodNo;
            Instruction."Form No." := FormNo;
            Instruction."Line No." := LineNo;
            Instruction.Insert();
        end;
        Instruction.Header := CopyStr(Header, 1, MaxStrLen(Instruction.Header));
        Instruction.Description := CopyStr(Description, 1, MaxStrLen(Instruction.Description));
        Instruction.Modify();
    end;

    local procedure AddNecFormInstructionLines(PeriodNo: Code[20])
    var
        IRS1099Form: Record "IRS 1099 Form";
    begin
        if not IRS1099Form.Get(PeriodNo, 'NEC') then
            exit;
        AddFormInstructionLine(PeriodNo, 'NEC', 1, '', NecGeneralInstructionTxt);
        AddFormInstructionLine(PeriodNo, 'NEC', 2, 'Recipient’s taxpayer identification number (TIN).', 'For your protection, this form may show only the last four digits of your TIN (social security number (SSN), individual taxpayer identification number (ITIN), adoption taxpayer identification number (ATIN), or employer identification number (EIN)). However, the issuer has reported your complete TIN to the IRS.');
        AddFormInstructionLine(PeriodNo, 'NEC', 3, 'Account number.', 'May show an account or other unique number the payer assigned to distinguish your account.');
        AddFormInstructionLine(PeriodNo, 'NEC', 4, 'Box 1.', NecCompensationInstructionTxt);
        AddFormInstructionLine(PeriodNo, 'NEC', 5, 'Note:', NecNoteInstructionTxt);
        AddFormInstructionLine(PeriodNo, 'NEC', 6, 'Box 2.', 'If checked, consumer products totaling $5,000 or more were sold to you for resale, on a buy-sell, a deposit-commission, or other basis. Generally, report any income from your sale of these products on Schedule C (Form 1040).');
        AddFormInstructionLine(PeriodNo, 'NEC', 7, 'Box 3.', 'Reserved for future use.');
        AddFormInstructionLine(PeriodNo, 'NEC', 8, 'Box 4.', 'Shows backup withholding. A payer must backup withhold on certain payments if you did not give your TIN to the payer. See Form W-9, Request for Taxpayer Identification Number and Certification, for information on backup withholding. Include this amount on your income tax return as tax withheld.');
        AddFormInstructionLine(PeriodNo, 'NEC', 9, 'Boxes 5-7.', 'State income tax withheld reporting boxes.');
        AddFormInstructionLine(PeriodNo, 'NEC', 10, 'Future developments.', 'For the latest information about developments related to Form 1099-NEC and its instructions, such as legislation enacted after they were published, go to www.irs.gov/Form1099NEC.');
        AddFormInstructionLine(PeriodNo, 'NEC', 11, 'Free File Program.', 'Go to www.irs.gov/FreeFile to see if you qualify for no-cost online federal tax preparation, e-filing, and direct deposit or payment options.');
    end;

    local procedure AddMiscFormInstructionLines(PeriodNo: Code[20])
    var
        IRS1099Form: Record "IRS 1099 Form";
    begin
        if not IRS1099Form.Get(PeriodNo, 'MISC') then
            exit;
        AddFormInstructionLine(PeriodNo, 'MISC', 1, 'Recipient’s taxpayer identification number (TIN).', 'For your protection, this form may show only the last four digits of your TIN (social security number (SSN), individual taxpayer identification number (ITIN), adoption taxpayer identification number (ATIN), or employer identification number (EIN)). However, the issuer has reported your complete TIN to the IRS.');
        AddFormInstructionLine(PeriodNo, 'MISC', 2, 'Account number.', 'May show an account or other unique number the payer assigned to distinguish your account.');
        AddFormInstructionLine(PeriodNo, 'MISC', 3, 'Amounts shown may be subject to self-employment (SE) tax.', 'Individuals should see the Instructions for Schedule SE (Form 1040). Corporations, fiduciaries, or partnerships must report the amounts on the appropriate line of their tax returns.');
        AddFormInstructionLine(PeriodNo, 'MISC', 4, 'Form 1099-MISC incorrect?', 'If this form is incorrect or has been issued in error, contact the payer. If you cannot get this form corrected, attach an explanation to your tax return and report your information correctly.');
        AddFormInstructionLine(PeriodNo, 'MISC', 5, 'Box 1.', 'Report rents from real estate on Schedule E (Form 1040). However, report rents on Schedule C (Form 1040) if you provided significant services to the tenant, sold real estate as a business, or rented personal property as a business. See Pub. 527.');
        AddFormInstructionLine(PeriodNo, 'MISC', 6, 'Box 2.', 'Report royalties from oil, gas, or mineral properties; copyrights; and patents on Schedule E (Form 1040). However, report payments for a working interest as explained in the Schedule E (Form 1040) instructions. For royalties on timber, coal, and iron ore, see Pub. 544.');
        AddFormInstructionLine(PeriodNo, 'MISC', 7, 'Box 3.', 'Generally, report this amount on the “Other income” line of Schedule 1 (Form 1040) and identify the payment. The amount shown may be payments received as the beneficiary of a deceased employee, prizes, awards, taxable damages, Indian gaming profits, or other taxable income. See Pub. 525. If it is trade or business income, report this amount on Schedule C or F (Form 1040).');
        AddFormInstructionLine(PeriodNo, 'MISC', 8, 'Box 4.', 'Shows backup withholding or withholding on Indian gaming profits. Generally, a payer must backup withhold if you did not furnish your TIN. See Form W-9 and Pub. 505 for more information. Report this amount on your income tax return as tax withheld.');
        AddFormInstructionLine(PeriodNo, 'MISC', 9, 'Box 5.', 'Shows the amount paid to you as a fishing boat crew member by the operator, who considers you to be self-employed. Self-employed individuals must report this amount on Schedule C (Form 1040). See Pub. 334.');
        AddFormInstructionLine(PeriodNo, 'MISC', 10, 'Box 6.', 'For individuals, report on Schedule C (Form 1040).');
        AddFormInstructionLine(PeriodNo, 'MISC', 11, 'Box 7.', 'If checked, consumer products totaling $5,000 or more were sold to you for resale, on a buy-sell, a deposit-commission, or other basis. Generally, report any income from your sale of these products on Schedule C (Form 1040).');
        AddFormInstructionLine(PeriodNo, 'MISC', 12, 'Box 8.', 'Shows substitute payments in lieu of dividends or tax-exempt interest received by your broker on your behalf as a result of a loan of your securities. Report on the “Other income” line of Schedule 1 (Form 1040).');
        AddFormInstructionLine(PeriodNo, 'MISC', 13, 'Box 9.', 'Report this amount on Schedule F (Form 1040).');
        AddFormInstructionLine(PeriodNo, 'MISC', 14, 'Box 10.', 'Shows gross proceeds paid to an attorney in connection with legal services. Report only the taxable part as income on your return.');
        AddFormInstructionLine(PeriodNo, 'MISC', 15, 'Box 11.', 'Shows the amount of cash you received for the sale of fish if you are in the trade or business of catching fish.');
        AddFormInstructionLine(PeriodNo, 'MISC', 16, 'Box 12.', 'May show current year deferrals as a nonemployee under a nonqualified deferred compensation (NQDC) plan that is subject to the requirements of section 409A plus any earnings on current and prior year deferrals.');
        AddFormInstructionLine(PeriodNo, 'MISC', 17, 'Box 13.', 'If the FATCA filing requirement box is checked, the payer is reporting on this Form 1099 to satisfy its account reporting requirement under chapter 4 of the Internal Revenue Code. You may also have a filing requirement. See the Instructions for Form 8938.');
        AddFormInstructionLine(PeriodNo, 'MISC', 18, 'Box 14.', 'Shows your total compensation of excess golden parachute payments subject to a 20% excise tax. See your tax return instructions for where to report.');
        AddFormInstructionLine(PeriodNo, 'MISC', 19, 'Box 15.', 'Shows income as a nonemployee under an NQDC plan that does not meet the requirements of section 409A. Any amount included in box 12 that is currently taxable is also included in this box. Report this amount as income on your tax return. This income is also subject to a substantial additional tax to be reported on Form 1040, 1040-SR, or 1040-NR. See the instructions for your tax return.');
        AddFormInstructionLine(PeriodNo, 'MISC', 20, 'Boxes 16-18.', 'Show state or local income tax withheld from the payments.');
        AddFormInstructionLine(PeriodNo, 'MISC', 21, 'Future developments.', 'For the latest information about developments related to Form 1099-MISC and its instructions, such as legislation enacted after they were published, go to www.irs.gov/Form1099MISC.');
        AddFormInstructionLine(PeriodNo, 'MISC', 22, 'Free File Program.', 'Go to www.irs.gov/FreeFile to see if you qualify for no-cost online federal tax preparation, e-filing, and direct deposit or payment options.');
    end;

    local procedure AddIntFormInstructionLines(PeriodNo: Code[20])
    var
        IRS1099Form: Record "IRS 1099 Form";
    begin
        if not IRS1099Form.Get(PeriodNo, 'INT') then
            exit;
        AddFormInstructionLine(PeriodNo, 'INT', 1, '', 'The information provided may be different for covered and noncovered securities. For a description of covered securities, see the Instructions for Form 8949. For a taxable covered security acquired at a premium, unless you notified the payer in writing in accordance with Regulations section 1.6045-1(n)(5) that you did not want to amortize the premium under section 171, or for a tax-exempt covered security acquired at a premium, your payer must generally report either (1) a net amount of interest that reflects the offset of the amount of interest paid to you by the amount of premium amortization allocable to the payment(s), or (2) a gross amount for both the interest paid to you and the premium amortization allocable to the payment(s). If you did notify your payer that you did not want to amortize the premium on a taxable covered security, then your payer will only report the gross amount of interest paid to you. For a noncovered security acquired at a premium, your payer is only required to report the gross amount of interest paid to you.');
        AddFormInstructionLine(PeriodNo, 'INT', 2, 'Recipient’s taxpayer identification number (TIN).', 'For your protection, this form may show only the last four digits of your TIN (social security number (SSN), individual taxpayer identification number (ITIN), adoption taxpayer identification number (ATIN), or employer identification number (EIN)). However, the issuer has reported your complete TIN to the IRS.');
        AddFormInstructionLine(PeriodNo, 'INT', 3, 'FATCA filing requirement.', 'If the FATCA filing requirement box is checked, the payer is reporting on this Form 1099 to satisfy its chapter 4 account reporting requirement. You may also have a filing requirement. See the Instructions for Form 8938.');
        AddFormInstructionLine(PeriodNo, 'INT', 4, 'Account number.', 'May show an account or other unique number the payer assigned to distinguish your account.');
        AddFormInstructionLine(PeriodNo, 'INT', 5, 'Box 1.', 'Shows taxable interest paid to you during the calendar year by the payer. This does not include interest shown in box 3. May also show the total amount of the credits from clean renewable energy bonds, new clean renewable energy bonds, qualified energy conservation bonds, qualified zone academy bonds, qualified school construction bonds, and build America bonds that must be included in your interest income. These amounts were treated as paid to you during the calendar year on the credit allowance dates (March 15, June 15, September 15, and December 15). For more information, see Form 8912. See the instructions above for a taxable covered security acquired at a premium.');
        AddFormInstructionLine(PeriodNo, 'INT', 6, 'Box 2.', 'Shows interest or principal forfeited because of early withdrawal of time savings. You may deduct this amount to figure your adjusted gross income on your income tax return. See the Instructions for Form 1040 to see where to take the deduction.');
        AddFormInstructionLine(PeriodNo, 'INT', 7, 'Box 3.', 'Shows interest on U.S. Savings Bonds, Treasury bills, Treasury bonds, and Treasury notes. This may or may not all be taxable. See Pub. 550. This interest is exempt from state and local income taxes. This interest is not included in box 1. See the instructions above for a taxable covered security acquired at a premium.');
        AddFormInstructionLine(PeriodNo, 'INT', 8, 'Box 4.', 'Shows backup withholding. Generally, a payer must backup withhold if you did not furnish your TIN or you did not furnish the correct TIN to the payer. See Form W-9. Include this amount on your income tax return as tax withheld.');
        AddFormInstructionLine(PeriodNo, 'INT', 9, 'Box 5.', 'Any amount shown is your share of investment expenses of a single-class REMIC. This amount is included in box 1. Note: This amount is not deductible.');
        AddFormInstructionLine(PeriodNo, 'INT', 10, 'Box 6.', 'Shows foreign tax paid. You may be able to claim this tax as a deduction or a credit on your Form 1040 or 1040-SR. See your tax return instructions.');
        AddFormInstructionLine(PeriodNo, 'INT', 11, 'Box 7.', 'Shows the country or U.S. possession to which the foreign tax was paid.');
        AddFormInstructionLine(PeriodNo, 'INT', 12, 'Box 8.', 'Shows tax-exempt interest paid to you during the calendar year by the payer. See how to report this amount in the Instructions for Form 1040. This amount may be subject to backup withholding. See Box 4 above. See the instructions above for a tax-exempt covered security acquired at a premium.');
        AddFormInstructionLine(PeriodNo, 'INT', 13, 'Box 9.', 'Shows tax-exempt interest subject to the alternative minimum tax. This amount is included in box 8. See the Instructions for Form 6251. See the instructions above for a tax-exempt covered security acquired at a premium.');
        AddFormInstructionLine(PeriodNo, 'INT', 14, 'Box 10.', 'For a taxable or tax-exempt covered security, if you made an election under section 1278(b) to include market discount in income as it accrues and you notified your payer of the election in writing in accordance with Regulations section 1.6045-1(n)(5), shows the market discount that accrued on the debt instrument during the year while held by you, unless it was reported on Form 1099-OID. For a taxable or tax-exempt covered security acquired on or after January 1, 2015, accrued market discount will be calculated on a constant yield basis unless you notified your payer in writing in accordance with Regulations section 1.6045-1(n)(5) that you did not want to make a constant yield election for market discount under section 1276(b). Report the accrued market discount on your income tax return as directed in the Instructions for Form 1040. Market discount on a tax-exempt security is includible in taxable income as interest income.');
        AddFormInstructionLine(PeriodNo, 'INT', 15, 'Box 11.', 'For a taxable covered security (other than a U.S. Treasury obligation), shows the amount of premium amortization allocable to the interest payment(s), unless you notified the payer in writing in accordance with Regulations section 1.6045-1(n)(5) that you did not want to amortize bond premium under section 171. If an amount is reported in this box, see the Instructions for Schedule B (Form 1040) to determine the net amount of interest includible in income on Form 1040 or 1040-SR with respect to the security. If an amount is not reported in this box for a taxable covered security acquired at a premium and the payer is reporting premium amortization, the payer has reported a net amount of interest in box 1. If the amount in box 11 is greater than the amount of interest paid on the covered security, see Regulations section 1.171-2(a)(4).');
        AddFormInstructionLine(PeriodNo, 'INT', 16, 'Box 12.', 'For a U.S. Treasury obligation that is a covered security, shows the amount of premium amortization allocable to the interest payment(s), unless you notified the payer in writing in accordance with Regulations section 1.6045-1(n)(5) that you did not want to amortize bond premium under section 171. If an amount is reported in this box, see the Instructions for Schedule B (Form 1040) to determine the net amount of interest includible in income on Form 1040 or 1040-SR with respect to the U.S. Treasury obligation. If an amount is not reported in this box for a U.S. Treasury obligation that is a covered security acquired at a premium and the payer is reporting premium amortization, the payer has reported a net amount of interest in box 3. If the amount in box 12 is greater than the amount of interest paid on the U.S. Treasury obligation, see Regulations section 1.171-2(a)(4).');
        AddFormInstructionLine(PeriodNo, 'INT', 17, 'Box 13.', 'For a tax-exempt covered security, shows the amount of premium amortization allocable to the interest payment(s). If an amount is reported in this box, see Pub. 550 to determine the net amount of tax-exempt interest reportable on Form 1040 or 1040-SR. If an amount is not reported in this box for a tax-exempt covered security acquired at a premium, the payer has reported a net amount of interest in box 8 or 9, whichever is applicable. If the amount in box 13 is greater than the amount of interest paid on the tax-exempt covered security, the excess is a nondeductible loss. See Regulations section 1.171-2(a)(4)(ii).');
        AddFormInstructionLine(PeriodNo, 'INT', 18, 'Box 14.', 'Shows CUSIP number(s) for tax-exempt bond(s) on which tax-exempt interest was paid, or tax credit bond(s) on which taxable interest was paid or tax credit was allowed, to you during the calendar year. If blank, no CUSIP number was issued for the bond(s).');
        AddFormInstructionLine(PeriodNo, 'INT', 19, 'Boxes 15-17.', 'State tax withheld reporting boxes.');
        AddFormInstructionLine(PeriodNo, 'INT', 20, 'Nominees.', 'If this form includes amounts belonging to another person(s), you are considered a nominee recipient. Complete a Form 1099-INT for each of the other owners showing the income allocable to each. File Copy A of the form with the IRS. Furnish Copy B to each owner. List yourself as the “payer” and the other owner(s) as the “recipient.” File Form(s) 1099-INT with Form 1096 with the Internal Revenue Service Center for your area. On Form 1096, list yourself as the “filer.” A spouse is not required to file a nominee return to show amounts owned by the other spouse');
        AddFormInstructionLine(PeriodNo, 'INT', 21, 'Future developments.', 'For the latest information about developments related to Form 1099-INT and its instructions, such as legislation enacted after they were published, go to www.irs.gov/Form1099INT.');
        AddFormInstructionLine(PeriodNo, 'INT', 22, 'Free File Program.', 'Go to www.irs.gov/FreeFile to see if you qualify for no-cost online federal tax preparation, e-filing, and direct deposit or payment options.');
    end;

    local procedure AddDivFormInstructionLines(PeriodNo: Code[20])
    var
        IRS1099Form: Record "IRS 1099 Form";
    begin
        if not IRS1099Form.Get(PeriodNo, 'DIV') then
            exit;
        AddFormInstructionLine(PeriodNo, 'DIV', 1, 'Recipient’s taxpayer identification number (TIN).', 'For your protection, this form may show only the last four digits of your TIN (SSN, ITIN, ATIN, or EIN). However, the issuer has reported your complete TIN to the IRS.');
        AddFormInstructionLine(PeriodNo, 'DIV', 2, 'Account number.', 'May show an account or other unique number the payer assigned to distinguish your account.');
        AddFormInstructionLine(PeriodNo, 'DIV', 3, 'Box 1a.', 'Shows total ordinary dividends that are taxable. Include this amount on the “Ordinary dividends” line of Form 1040 or 1040-SR. Also report it on Schedule B (Form 1040), if required.');
        AddFormInstructionLine(PeriodNo, 'DIV', 4, 'Box 1b.', 'Shows the portion of the amount in box 1a that may be eligible for reduced capital gains rates. See the Instructions for Form 1040 for how to determine this amount and where to report. The amount shown may be dividends a corporation paid directly to you as a participant (or beneficiary of a participant) in an employee stock ownership plan (ESOP). Report it as a dividend on your Form 1040 or 1040-SR but treat it as a plan distribution, not as investment income, for any other purpose.');
        AddFormInstructionLine(PeriodNo, 'DIV', 5, 'Box 2a.', 'Shows total capital gain distributions from a regulated investment company (RIC) or real estate investment trust (REIT). See How To Report in the Instructions for Schedule D (Form 1040). But, if no amount is shown in boxes 2b, 2c, 2d, and 2f and your only capital gains and losses are capital gain distributions, you may be able to report the amounts shown in box 2a on your Form 1040 or 1040-SR rather than Schedule D. See the Instructions for Form 1040.');
        AddFormInstructionLine(PeriodNo, 'DIV', 6, 'Box 2b.', 'Shows the portion of the amount in box 2a that is unrecaptured section 1250 gain from certain depreciable real property. See the Unrecaptured Section 1250 Gain Worksheet in the Instructions for Schedule D (Form 1040).');
        AddFormInstructionLine(PeriodNo, 'DIV', 7, 'Box 2c.', 'Shows the portion of the amount in box 2a that is section 1202 gain from certain small business stock that may be subject to an exclusion. See the Schedule D (Form 1040) instructions.');
        AddFormInstructionLine(PeriodNo, 'DIV', 8, 'Box 2d.', 'Shows the portion of the amount in box 2a that is 28% rate gain from sales or exchanges of collectibles. If required, use this amount when completing the 28% Rate Gain Worksheet in the Instructions for Schedule D (Form 1040).');
        AddFormInstructionLine(PeriodNo, 'DIV', 9, 'Box 2e.', 'Shows the portion of the amount in box 1a that is section 897 gain attributable to disposition of U.S. real property interests (USRPI).');
        AddFormInstructionLine(PeriodNo, 'DIV', 10, 'Box 2f.', 'Shows the portion of the amount in box 2a that is section 897 gain attributable to disposition of USRPI.');
        AddFormInstructionLine(PeriodNo, 'DIV', 11, 'Note:', 'Boxes 2e and 2f apply only to foreign persons and entities whose income maintains its character when passed through or distributed to its direct or indirect foreign owners or beneficiaries. It is generally treated as effectively connected to a trade or business within the United States. See the instructions for your tax return.');
        AddFormInstructionLine(PeriodNo, 'DIV', 12, 'Box 3.', 'Shows a return of capital. To the extent of your cost (or other basis) in the stock, the distribution reduces your basis and is not taxable. Any amount received in excess of your basis is taxable to you as capital gain. See Pub. 550.');
        AddFormInstructionLine(PeriodNo, 'DIV', 13, 'Box 4.', 'Shows backup withholding. A payer must backup withhold on certain payments if you did not give your TIN to the payer. See Form W-9 for information on backup withholding. Include this amount on your income tax return as tax withheld.');
        AddFormInstructionLine(PeriodNo, 'DIV', 14, 'Box 5.', 'Shows the portion of the amount in box 1a that may be eligible for the 20% qualified business income deduction under section 199A. See the instructions for Form 8995 and Form 8995-A.');
        AddFormInstructionLine(PeriodNo, 'DIV', 15, 'Box 6.', 'Shows your share of expenses of a nonpublicly offered RIC, generally a nonpublicly offered mutual fund. This amount is included in box 1a.');
        AddFormInstructionLine(PeriodNo, 'DIV', 16, 'Box 7.', 'Shows the foreign tax that you may be able to claim as a deduction or a credit on Form 1040 or 1040-SR. See the Instructions for Form 1040.');
        AddFormInstructionLine(PeriodNo, 'DIV', 17, 'Box 8.', 'This box should be left blank if a RIC reported the foreign tax shown in box 7.');
        AddFormInstructionLine(PeriodNo, 'DIV', 18, 'Boxes 9 and 10.', 'Show cash and noncash liquidation distributions.');
        AddFormInstructionLine(PeriodNo, 'DIV', 19, 'Box 11.', 'If the FATCA filing requirement box is checked, the payer is reporting on this Form 1099 to satisfy its account reporting requirement under chapter 4 of the Internal Revenue Code. You may also have a filing requirement. See the Instructions for Form 8938.');
        AddFormInstructionLine(PeriodNo, 'DIV', 20, 'Box 12.', 'Shows exempt-interest dividends from a mutual fund or other RIC paid to you during the calendar year. See the Instructions for Form 1040 for where to report. This amount may be subject to backup withholding. See Box 4 above.');
        AddFormInstructionLine(PeriodNo, 'DIV', 21, 'Box 13.', 'Shows exempt-interest dividends subject to the alternative minimum tax. This amount is included in box 12. See the Instructions for Form 6251.');
        AddFormInstructionLine(PeriodNo, 'DIV', 22, 'Boxes 14-16.', 'State income tax withheld reporting boxes.');
        AddFormInstructionLine(PeriodNo, 'DIV', 23, 'Nominees.', 'If this form includes amounts belonging to another person, you are considered a nominee recipient. You must file Form 1099-DIV (with a Form 1096) with the IRS for each of the other owners to show their share of the income, and you must furnish a Form 1099-DIV to each. A spouse is not required to file a nominee return to show amounts owned by the other spouse. See the current General Instructions for Certain Information Returns.');
    end;

    local procedure AddReportingPeriod(PeriodNo: Code[20]; StartingDate: Date; EndingDate: Date; Description: Text): Code[20]
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        IRSReportingPeriod.Validate("No.", PeriodNo);
        IRSReportingPeriod.Validate("Starting Date", StartingDate);
        IRSReportingPeriod.Validate("Ending Date", EndingDate);
        IRSReportingPeriod.Validate("Description", CopyStr(Description, 1, MaxStrLen(IRSReportingPeriod.Description)));
        IRSReportingPeriod.Insert(true);
        exit(IRSReportingPeriod."No.");
    end;

    local procedure AddForm(PeriodNo: Code[20]; FormNo: Code[20]; Description: Text)
    var
        IRS1099Form: Record "IRS 1099 Form";
    begin
        IRS1099Form.Validate("Period No.", PeriodNo);
        IRS1099Form.Validate("No.", FormNo);
        IRS1099Form.Validate("Description", CopyStr(Description, 1, MaxStrLen(IRS1099Form.Description)));
        IRS1099Form.Insert(true);
    end;

    procedure AddFormBox(PeriodNo: Code[20]; FormNo: Code[20]; FormBoxNo: Code[20]; Description: Text; MinimumReportableAmount: Decimal)
    var
        IRS1099FormBox: Record "IRS 1099 Form Box";
    begin
        IRS1099FormBox.Validate("Period No.", PeriodNo);
        IRS1099FormBox.Validate("Form No.", FormNo);
        IRS1099FormBox.Validate("No.", FormBoxNo);
        IRS1099FormBox.Validate("Description", CopyStr(Description, 1, MaxStrLen(IRS1099FormBox.Description)));
        IRS1099FormBox.Validate("Minimum Reportable Amount", MinimumReportableAmount);
        IRS1099FormBox.Insert(true);
    end;

    procedure AddFormStatementLine(PeriodNo: Code[20]; FormNo: Code[20]; FormBoxNo: Code[20]; StatementLineNo: Integer; Description: Text)
    begin
        AddFormStatementLine(PeriodNo, FormNo, Enum::"IRS 1099 Print Value Type"::Amount, FormBoxNo, StatementLineNo, Description);
    end;

    local procedure AddFormStatementLine(PeriodNo: Code[20]; FormNo: Code[20]; Type: Enum "IRS 1099 Print Value Type"; FormBoxNo: Code[20]; StatementLineNo: Integer; Description: Text)
    var
        IRS1099FormStatementLine: Record "IRS 1099 Form Statement Line";
    begin
        IRS1099FormStatementLine.Validate("Period No.", PeriodNo);
        IRS1099FormStatementLine.Validate("Form No.", FormNo);
        IRS1099FormStatementLine.Validate("Line No.", StatementLineNo);
        IRS1099FormStatementLine.Validate("Print Value Type", Type);
        IRS1099FormStatementLine.Validate("Row No.", FormBoxNo);
        IRS1099FormStatementLine.Validate("Description", CopyStr(Description, 1, MaxStrLen(IRS1099FormStatementLine.Description)));
        IRS1099FormStatementLine.SetFormBoxFilter(FormBoxNo);
        IRS1099FormStatementLine.Insert(true);
    end;

    local procedure AddFormInstructionLine(PeriodNo: Code[20]; FormNo: Code[20]; LineNo: Integer; Header: Text; Description: Text)
    var
        IRS1099FormInstruction: Record "IRS 1099 Form Instruction";
    begin
        IRS1099FormInstruction.Validate("Period No.", PeriodNo);
        IRS1099FormInstruction.Validate("Form No.", FormNo);
        IRS1099FormInstruction.Validate("Line No.", LineNo);
        IRS1099FormInstruction.Validate(Header, CopyStr(Header, 1, MaxStrLen(IRS1099FormInstruction.Header)));
        IRS1099FormInstruction.Validate(Description, CopyStr(Description, 1, MaxStrLen(IRS1099FormInstruction.Description)));
        IRS1099FormInstruction.Insert(true);
    end;

    procedure GetNameControl(): Code[4]
    var
        CompanyInformation: Record "Company Information";
        TypeHelper: Codeunit "Type Helper";
        CompanyName: Text;
        TB: TextBuilder;
        WordsCount: Integer;
        Ch: Char;
    begin
        CompanyInformation.Get();
        CompanyName := RemoveExtraSpaces(CompanyInformation.Name);
        CompanyName := UpperCase(CompanyName);

        // omit 'The' when it is followed by more than one word
        if CompanyName.StartsWith('THE ') then begin
            WordsCount := CompanyName.Split(' ').Count;
            if WordsCount > 2 then
                CompanyName := CompanyName.Substring(5);
        end;

        // allowed chars are A-Z, 0-9, hyphen, and ampersand
        foreach Ch in CompanyName do
            if TypeHelper.IsLatinLetter(Ch) or TypeHelper.IsDigit(Ch) or
               (Ch = '-') or (Ch = '&')
            then
                TB.Append(Ch);

        // take the first four characters of the name
        exit(CopyStr(TB.ToText(), 1, 4));
    end;

    procedure RemoveExtraSpaces(InputText: Text): Text
    var
        TB: TextBuilder;
        Ch: Char;
        PrevIsSpace: Boolean;
    begin
        // remove leading and trailing spaces
        InputText := InputText.Trim();

        // remove adjacent spaces
        foreach Ch in InputText do
            if Ch = ' ' then begin
                if not PrevIsSpace then
                    TB.Append(Ch);
                PrevIsSpace := true;
            end else begin
                TB.Append(Ch);
                PrevIsSpace := false;
            end;

        exit(TB.ToText());
    end;
}
