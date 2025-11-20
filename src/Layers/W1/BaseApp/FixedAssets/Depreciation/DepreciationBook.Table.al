// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Finance.Currency;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;

table 5611 "Depreciation Book"
{
    Caption = 'Depreciation Book';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Depreciation Book List";
    LookupPageID = "Depreciation Book List";
    Permissions = TableData "FA Posting Type Setup" = rimd,
                  TableData "FA Depreciation Book" = rm;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code that identifies the depreciation book.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the purpose of the depreciation book.';
        }
        field(3; "G/L Integration - Acq. Cost"; Boolean)
        {
            Caption = 'G/L Integration - Acq. Cost';
        }
        field(4; "G/L Integration - Depreciation"; Boolean)
        {
            Caption = 'G/L Integration - Depreciation';
        }
        field(5; "G/L Integration - Write-Down"; Boolean)
        {
            Caption = 'G/L Integration - Write-Down';
        }
        field(6; "G/L Integration - Appreciation"; Boolean)
        {
            Caption = 'G/L Integration - Appreciation';
        }
        field(7; "G/L Integration - Custom 1"; Boolean)
        {
            Caption = 'G/L Integration - Custom 1';
        }
        field(8; "G/L Integration - Custom 2"; Boolean)
        {
            Caption = 'G/L Integration - Custom 2';
        }
        field(9; "G/L Integration - Disposal"; Boolean)
        {
            Caption = 'G/L Integration - Disposal';
        }
        field(10; "G/L Integration - Maintenance"; Boolean)
        {
            Caption = 'G/L Integration - Maintenance';
        }
        field(11; "Disposal Calculation Method"; Option)
        {
            Caption = 'Disposal Calculation Method';
            OptionCaption = 'Net,Gross';
            OptionMembers = Net,Gross;
        }
        field(12; "Use Custom 1 Depreciation"; Boolean)
        {
            Caption = 'Use Custom 1 Depreciation';

            trigger OnValidate()
            begin
                if "Use Custom 1 Depreciation" then
                    TestField("Fiscal Year 365 Days", false);
            end;
        }
        field(13; "Allow Depr. below Zero"; Boolean)
        {
            Caption = 'Allow Depr. below Zero';
        }
        field(14; "Use FA Exch. Rate in Duplic."; Boolean)
        {
            Caption = 'Use FA Exch. Rate in Duplic.';

            trigger OnValidate()
            begin
                if not "Use FA Exch. Rate in Duplic." then
                    "Default Exchange Rate" := 0;
            end;
        }
        field(15; "Part of Duplication List"; Boolean)
        {
            Caption = 'Part of Duplication List';
        }
        field(17; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(18; "Allow Indexation"; Boolean)
        {
            Caption = 'Allow Indexation';
        }
        field(19; "Use Same FA+G/L Posting Dates"; Boolean)
        {
            Caption = 'Use Same FA+G/L Posting Dates';
            InitValue = true;
        }
        field(20; "Default Exchange Rate"; Decimal)
        {
            Caption = 'Default Exchange Rate';
            DecimalPlaces = 4 : 4;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Default Exchange Rate" > 0 then
                    TestField("Use FA Exch. Rate in Duplic.", true);
            end;
        }
        field(23; "Use FA Ledger Check"; Boolean)
        {
            Caption = 'Use FA Ledger Check';
            InitValue = true;
        }
        field(24; "Use Rounding in Periodic Depr."; Boolean)
        {
            Caption = 'Use Rounding in Periodic Depr.';
        }
        field(25; "New Fiscal Year Starting Date"; Date)
        {
            Caption = 'New Fiscal Year Starting Date';
        }
        field(26; "No. of Days in Fiscal Year"; Integer)
        {
            Caption = 'No. of Days in Fiscal Year';
            MaxValue = 1080;
            MinValue = 10;
        }
        field(27; "Allow Changes in Depr. Fields"; Boolean)
        {
            Caption = 'Allow Changes in Depr. Fields';
        }
        field(28; "Default Final Rounding Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Default Final Rounding Amount';
            MinValue = 0;
        }
        field(29; "Default Ending Book Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Default Ending Book Value';
            MinValue = 0;
        }
        field(32; "Periodic Depr. Date Calc."; Option)
        {
            Caption = 'Periodic Depr. Date Calc.';
            OptionCaption = 'Last Entry,Last Depr. Entry';
            OptionMembers = "Last Entry","Last Depr. Entry";

            trigger OnValidate()
            begin
                if "Periodic Depr. Date Calc." <> "Periodic Depr. Date Calc."::"Last Entry" then
                    TestField("Fiscal Year 365 Days", false);
            end;
        }
        field(33; "Mark Errors as Corrections"; Boolean)
        {
            Caption = 'Mark Errors as Corrections';
        }
        field(34; "Add-Curr Exch Rate - Acq. Cost"; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add-Curr Exch Rate - Acq. Cost';
        }
        field(35; "Add.-Curr. Exch. Rate - Depr."; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add.-Curr. Exch. Rate - Depr.';
        }
        field(36; "Add-Curr Exch Rate -Write-Down"; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add-Curr Exch Rate -Write-Down';
        }
        field(37; "Add-Curr. Exch. Rate - Apprec."; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add-Curr. Exch. Rate - Apprec.';
        }
        field(38; "Add-Curr. Exch Rate - Custom 1"; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add-Curr. Exch Rate - Custom 1';
        }
        field(39; "Add-Curr. Exch Rate - Custom 2"; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add-Curr. Exch Rate - Custom 2';
        }
        field(40; "Add.-Curr. Exch. Rate - Disp."; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add.-Curr. Exch. Rate - Disp.';
        }
        field(41; "Add.-Curr. Exch. Rate - Maint."; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add.-Curr. Exch. Rate - Maint.';
        }
        field(42; "Use Default Dimension"; Boolean)
        {
            Caption = 'Use Default Dimension';
        }
        field(43; "Subtract Disc. in Purch. Inv."; Boolean)
        {
            Caption = 'Subtract Disc. in Purch. Inv.';
        }
        field(44; "Allow Correction of Disposal"; Boolean)
        {
            Caption = 'Allow Correction of Disposal';
        }
        field(45; "Allow more than 360/365 Days"; Boolean)
        {
            Caption = 'Allow more than 360/365 Days';
        }
        field(46; "VAT on Net Disposal Entries"; Boolean)
        {
            Caption = 'VAT on Net Disposal Entries';
        }
        field(47; "Allow Acq. Cost below Zero"; Boolean)
        {
            Caption = 'Allow Acq. Cost below Zero';
        }
        field(48; "Allow Identical Document No."; Boolean)
        {
            Caption = 'Allow Identical Document No.';
        }
        field(49; "Fiscal Year 365 Days"; Boolean)
        {
            Caption = 'Fiscal Year 365 Days';

            trigger OnValidate()
            var
                FADeprBook: Record "FA Depreciation Book";
            begin
                if "Fiscal Year 365 Days" then begin
                    TestField("Use Custom 1 Depreciation", false);
                    TestField("Periodic Depr. Date Calc.", "Periodic Depr. Date Calc."::"Last Entry");
                end;
                FADeprBook.LockTable();
                Modify();
                FADeprBook.SetCurrentKey("Depreciation Book Code", "FA No.");
                FADeprBook.SetRange("Depreciation Book Code", Code);
                if FADeprBook.FindSet(true) then
                    repeat
                        FADeprBook.CalcDeprPeriod();
                        FADeprBook.Modify();
                    until FADeprBook.Next() = 0;
            end;
        }
        field(10500; "Use Accounting Period"; Boolean)
        {
            Caption = 'Use Accounting Period';

            trigger OnValidate()
            var
                FADeprBook: Record "FA Depreciation Book";
            begin
                if "Use Accounting Period" then begin
                    FADeprBook.SetRange("Depreciation Book Code", Code);
                    FADeprBook.SetFilter("Depreciation Method", '<> %1', FADeprBook."Depreciation Method"::"Straight-Line");
                    if not FADeprBook.IsEmpty() then
                        Error(MustBeStraightLineTxt, FieldCaption("Use Accounting Period"), true);
                end;
            end;
        }
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

    trigger OnDelete()
    var
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        FADeprBook: Record "FA Depreciation Book";
    begin
        FASetup.Get();
        FADeprBook.SetCurrentKey("Depreciation Book Code");
        FADeprBook.SetRange("Depreciation Book Code", Code);
        if not FADeprBook.IsEmpty() then
            Error(Text000);

        if not InsCoverageLedgEntry.IsEmpty() and (FASetup."Insurance Depr. Book" = Code) then
            Error(
              Text001,
              FASetup.TableCaption(), FASetup.FieldCaption("Insurance Depr. Book"), Code);

        FAPostingTypeSetup.SetRange("Depreciation Book Code", Code);
        FAPostingTypeSetup.DeleteAll();

        FAJnlSetup.SetRange("Depreciation Book Code", Code);
        FAJnlSetup.DeleteAll();
    end;

    trigger OnInsert()
    begin
        FAPostingTypeSetup."Depreciation Book Code" := Code;
        FAPostingTypeSetup."FA Posting Type" := FAPostingTypeSetup."FA Posting Type"::Appreciation;
        FAPostingTypeSetup."Part of Book Value" := true;
        FAPostingTypeSetup."Part of Depreciable Basis" := true;
        FAPostingTypeSetup."Include in Depr. Calculation" := true;
        FAPostingTypeSetup."Include in Gain/Loss Calc." := false;
        FAPostingTypeSetup."Depreciation Type" := false;
        FAPostingTypeSetup."Acquisition Type" := true;
        FAPostingTypeSetup.Sign := FAPostingTypeSetup.Sign::Debit;
        FAPostingTypeSetup.Insert();
        FAPostingTypeSetup."FA Posting Type" := FAPostingTypeSetup."FA Posting Type"::"Write-Down";
        FAPostingTypeSetup."Part of Depreciable Basis" := false;
        FAPostingTypeSetup."Include in Gain/Loss Calc." := true;
        FAPostingTypeSetup."Depreciation Type" := true;
        FAPostingTypeSetup."Acquisition Type" := false;
        FAPostingTypeSetup.Sign := FAPostingTypeSetup.Sign::Credit;
        FAPostingTypeSetup.Insert();
        FAPostingTypeSetup."FA Posting Type" := FAPostingTypeSetup."FA Posting Type"::"Custom 1";
        FAPostingTypeSetup.Insert();
        FAPostingTypeSetup."FA Posting Type" := FAPostingTypeSetup."FA Posting Type"::"Custom 2";
        FAPostingTypeSetup.Insert();
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        "Last Date Modified" := Today;
    end;

    var
        FASetup: Record "FA Setup";
        FAJnlSetup: Record "FA Journal Setup";
        MustBeStraightLineTxt: Label 'You cannot set %1 to %2 because some Fixed Assets associated with this book\exists where Depreciation Method is other than Straight-Line.',Comment ='%1="Use Accounting Period" Field Caption %2="Use Accounting Period" Field Value';

#pragma warning disable AA0074
        Text000: Label 'The book cannot be deleted because it is in use.';
#pragma warning disable AA0470
        Text001: Label 'The book cannot be deleted because %1 %2 = %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        FAPostingTypeSetup: Record "FA Posting Type Setup";

    procedure IndexGLIntegration(var GLIntegration: array[9] of Boolean)
    begin
        GLIntegration[1] := "G/L Integration - Acq. Cost";
        GLIntegration[2] := "G/L Integration - Depreciation";
        GLIntegration[3] := "G/L Integration - Write-Down";
        GLIntegration[4] := "G/L Integration - Appreciation";
        GLIntegration[5] := "G/L Integration - Custom 1";
        GLIntegration[6] := "G/L Integration - Custom 2";
        GLIntegration[7] := "G/L Integration - Disposal";
        GLIntegration[8] := "G/L Integration - Maintenance";
        GLIntegration[9] := false; // Salvage Value
    end;
}

