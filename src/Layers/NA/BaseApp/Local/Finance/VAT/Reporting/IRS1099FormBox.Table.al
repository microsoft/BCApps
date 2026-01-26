#if not CLEANSCHEMA28 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 10010 "IRS 1099 Form-Box"
{
    Caption = 'IRS 1099 Form-Box';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Minimum Reportable"; Decimal)
        {
            Caption = 'Minimum Reportable';
            DecimalPlaces = 2 : 2;
        }
        field(4; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(10; "Adjustment Exists"; Integer)
        {
            CalcFormula = count("IRS 1099 Adjustment" where("IRS 1099 Code" = field(Code)));
            Editable = false;
            FieldClass = FlowField;
        }
#if not CLEANSCHEMA28
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
        }
#endif
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnRename()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    procedure InitIRS1099FormBoxes()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        if not IRS1099FormBox.FindFirst() then begin
            InsertIRS1099('B', 'Proceeds From Broker+Barter Exchange Transactions', 0.0);
            InsertIRS1099('B-02', 'Stocks, bonds, etc.', 0.0);
            InsertIRS1099('B-03', 'Bartering', 0.0);
            InsertIRS1099('B-04', 'Federal income tax withheld', 0.0);
            InsertIRS1099('B-06', 'Profit/loss realized - this year', 0.0);
            InsertIRS1099('B-07', 'Unreal. profit/loss on open contracts - last year', 0.0);
            InsertIRS1099('B-08', 'Unreal. profit/loss on open contracts - this year', 0.0);
            InsertIRS1099('B-09', 'Aggregate profit/loss', 0.0);
            InsertIRS1099('DIV', 'Dividends and Distributions', 0.0);
            InsertIRS1099('DIV-01-A', 'Total ordinary dividends', 10.0);
            InsertIRS1099('DIV-01-B', 'Qualified dividends', 10.0);
            InsertIRS1099('DIV-02-A', 'Total capital gain distr.', 0.0);
            InsertIRS1099('DIV-02-B', 'Unrecap. Sec. 1250 gain', 10.0);
            InsertIRS1099('DIV-02-C', 'Section 1202 gain', 0.0);
            InsertIRS1099('DIV-02-D', 'Collectibles (28%) gain', 0.0);
            InsertIRS1099('DIV-02-E', 'Section 897 ordinary dividends', 0.0);
            InsertIRS1099('DIV-02-F', 'Section 897 capital gain', 0.0);
            InsertIRS1099('DIV-03', 'Nondividend distributions', 10.0);
            InsertIRS1099('DIV-04', 'Federal income tax withheld', -1.0);
            InsertIRS1099('DIV-05', 'Section 199A dividends', 10.0);
            InsertIRS1099('DIV-06', 'Investment expenses', 10.0);
            InsertIRS1099('DIV-07', 'Foreign tax paid', -1.0);
            InsertIRS1099('DIV-09', 'Cash liquidation distributions', 600.0);
            InsertIRS1099('DIV-10', 'Noncash liquidation distributions', 600.0);
            InsertIRS1099('DIV-12', 'Exempt-interest dividends', 0.0);
            InsertIRS1099('DIV-13', 'Specified private activity bond interest dividends', 0.0);
            InsertIRS1099('INT', 'Interest Income', 0.0);
            InsertIRS1099('INT-01', 'Interest income', 10.0);
            InsertIRS1099('INT-02', 'Early withdrawal penalty', -1.0);
            InsertIRS1099('INT-03', 'Interest on US Savings Bonds and Treas. obligations', 10.0);
            InsertIRS1099('INT-04', 'Federal income tax withheld', -1.0);
            InsertIRS1099('INT-05', 'Investment expenses', 10.0);
            InsertIRS1099('INT-06', 'Foreign tax paid', -1.0);
            InsertIRS1099('INT-08', 'Tax-exempt interest', 10.0);
            InsertIRS1099('INT-09', 'Specified private activity bond interest', 10.0);
            InsertIRS1099('INT-10', 'Market discount', 10.0);
            InsertIRS1099('INT-11', 'Bond premium', 0.01);
            InsertIRS1099('INT-12', 'Bond Premium on Treasury Obligation', 0.01);
            InsertIRS1099('INT-13', 'Bond premium on tax-exempt bond', 0.01);
            InsertIRS1099('MISC', 'Miscellaneous Income', 0.0);
            InsertIRS1099('MISC-01', 'Rents', 600.0);
            InsertIRS1099('MISC-02', 'Royalties', 10.0);
            InsertIRS1099('MISC-03', 'Other Income', 600.0);
            InsertIRS1099('MISC-04', 'Federal income tax withheld', -1.0);
            InsertIRS1099('MISC-05', 'Fishing boat proceeds', 1.0);
            InsertIRS1099('MISC-06', 'Medical and health care payments', 600.0);
            InsertIRS1099('MISC-07', 'Payer made direct sales of $5000 or more of consumer products', 5000.0);
            InsertIRS1099('MISC-08', 'Substitute payments in lieu of dividends or interest', 10.0);
            InsertIRS1099('MISC-09', 'Crop insurance proceeds', 1.0);
            InsertIRS1099('MISC-10', 'Gross proceeds paid to an attorney', 0.0);
            InsertIRS1099('MISC-11', 'Fish purchased for resale', 600.0);
            InsertIRS1099('MISC-12', 'Section 409A deferrals', 600.0);
            InsertIRS1099('MISC-14', 'Excess golden parachute payments', 0.0);
            InsertIRS1099('MISC-15', 'Nonqualified deferred compensation', 0.0);
            InsertIRS1099('MISC-16', 'State tax withheld', 0.0);
            InsertIRS1099('NEC-01', 'Nonemployee compensation', 600.0);
            InsertIRS1099(
              'NEC-02', 'Payer made direct sales totaling $5,000 or more of consumer products to recipient for resale', 5000.0);
            InsertIRS1099('NEC-04', 'Federal income tax withheld', 0.0);
            InsertIRS1099('R', 'Pensions/Ann./Retirement/Profit-Shar.Plans/IRAs...', 0.0);
            InsertIRS1099('R-01', 'Gross distribution', 0.0);
            InsertIRS1099('R-02A', 'Taxable Amount', 0.0);
            InsertIRS1099('R-03', 'Amount in Box 2 eligible for capital gain election', 0.0);
            InsertIRS1099('R-04', 'Federal income tax withheld', 0.0);
            InsertIRS1099('R-05', 'Employee contributions/insurance premiums', 0.0);
            InsertIRS1099('R-06', 'Net unreal. appreciation in employers securities', 0.0);
            InsertIRS1099('R-10', 'State income tax withheld', 0.0);
            InsertIRS1099('R-12', 'Local income tax withheld', 0.0);
            InsertIRS1099('S', 'Proceeds From Real Estate Transactions', 0.0);
            InsertIRS1099('S-02', 'Gross proceeds', 0.0);
        end;
    end;

    local procedure InsertIRS1099(NewCode: Code[10]; NewDescription: Text[100]; NewMinimum: Decimal)
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.Init();
        IRS1099FormBox.Code := NewCode;
        IRS1099FormBox.Description := NewDescription;
        IRS1099FormBox."Minimum Reportable" := NewMinimum;
        IRS1099FormBox.Insert();
    end;
} 
#endif