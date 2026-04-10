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
            ToolTip = 'Specifies whether acquisition cost entries posted to this depreciation book are posted both to the general ledger and the FA ledger.';

            trigger OnValidate()
            begin
                CheckIntegrationFields();
            end;
        }
        field(4; "G/L Integration - Depreciation"; Boolean)
        {
            Caption = 'G/L Integration - Depreciation';
            ToolTip = 'Specifies whether depreciation entries posted to this depreciation book are posted both to the general ledger and the FA ledger.';

            trigger OnValidate()
            begin
                CheckIntegrationFields();
            end;
        }
        field(5; "G/L Integration - Write-Down"; Boolean)
        {
            Caption = 'G/L Integration - Write-Down';
            ToolTip = 'Specifies whether write-down entries posted to this depreciation book should be posted to the general ledger and the FA ledger.';

            trigger OnValidate()
            begin
                CheckIntegrationFields();
            end;
        }
        field(6; "G/L Integration - Appreciation"; Boolean)
        {
            Caption = 'G/L Integration - Appreciation';
            ToolTip = 'Specifies whether appreciation entries posted to this depreciation book are posted to the general ledger and the FA ledger.';

            trigger OnValidate()
            begin
                CheckIntegrationFields();
            end;
        }
        field(7; "G/L Integration - Custom 1"; Boolean)
        {
            Caption = 'G/L Integration - Custom 1';
            ToolTip = 'Specifies whether custom 1 entries posted to this depreciation book are posted to the general ledger and the FA ledger.';

            trigger OnValidate()
            begin
                CheckIntegrationFields();
            end;
        }
        field(8; "G/L Integration - Custom 2"; Boolean)
        {
            Caption = 'G/L Integration - Custom 2';
            ToolTip = 'Specifies whether custom 2 entries posted to this depreciation book are posted to the general ledger and the FA ledger.';

            trigger OnValidate()
            begin
                CheckIntegrationFields();
            end;
        }
        field(9; "G/L Integration - Disposal"; Boolean)
        {
            Caption = 'G/L Integration - Disposal';
            ToolTip = 'Specifies whether disposal entries posted to this depreciation book are posted to the general ledger and the FA ledger.';

            trigger OnValidate()
            begin
                CheckIntegrationFields();
            end;
        }
        field(10; "G/L Integration - Maintenance"; Boolean)
        {
            Caption = 'G/L Integration - Maintenance';
            ToolTip = 'Specifies whether maintenance entries that are posted to this depreciation book are posted both to the general ledger and the FA ledger.';

            trigger OnValidate()
            begin
                CheckIntegrationFields();
            end;
        }
        field(11; "Disposal Calculation Method"; Option)
        {
            Caption = 'Disposal Calculation Method';
            ToolTip = 'Specifies the disposal method for the current depreciation book.';
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
            ToolTip = 'Specifies whether to allow the Calculate Depreciation batch job to continue calculating depreciation even if the book value is zero or below.';
        }
        field(14; "Use FA Exch. Rate in Duplic."; Boolean)
        {
            Caption = 'Use FA Exch. Rate in Duplic.';
            ToolTip = 'Specifies whether to use the FA Exchange Rate field when you duplicate entries from one depreciation book to another.';

            trigger OnValidate()
            begin
                if not "Use FA Exch. Rate in Duplic." then
                    "Default Exchange Rate" := 0;
            end;
        }
        field(15; "Part of Duplication List"; Boolean)
        {
            Caption = 'Part of Duplication List';
            ToolTip = 'Specifies whether to indicate that entries made in another depreciation book should be duplicated to this depreciation book.';
        }
        field(16; "G/L Integration - Bonus Depr."; Boolean)
        {
            Caption = 'G/L Integration - Bonus Depreciation';
            ToolTip = 'Specifies whether bonus depreciation entries that are posted to this depreciation book are posted both to the general ledger and the FA ledger.';
        }
        field(17; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(18; "Allow Indexation"; Boolean)
        {
            Caption = 'Allow Indexation';
            ToolTip = 'Specifies whether to allow indexation of FA ledger entries and maintenance ledger entries posted to this book.';
        }
        field(19; "Use Same FA+G/L Posting Dates"; Boolean)
        {
            Caption = 'Use Same FA+G/L Posting Dates';
            ToolTip = 'Specifies whether to indicate that the Posting Date and the FA Posting Date must be the same on a journal line before posting.';
            InitValue = true;
        }
        field(20; "Default Exchange Rate"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Default Exchange Rate';
            ToolTip = 'Specifies the exchange rate to use if the rate in the FA Exchange Rate field is zero.';
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
            ToolTip = 'Specifies which checks to perform before posting a journal line.';
            InitValue = true;
        }
        field(24; "Use Rounding in Periodic Depr."; Boolean)
        {
            Caption = 'Use Rounding in Periodic Depr.';
            ToolTip = 'Specifies whether the calculated periodic depreciation amounts should be rounded to whole numbers.';
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
            ToolTip = 'Specifies whether to allow the depreciation fields to be modified.';
        }
        field(28; "Default Final Rounding Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            Caption = 'Default Final Rounding Amount';
            ToolTip = 'Specifies the final rounding amount to use if the Final Rounding Amount field is zero.';
            MinValue = 0;
        }
        field(29; "Default Ending Book Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            Caption = 'Default Ending Book Value';
            ToolTip = 'Specifies the ending book value to use if the Ending Book Value field is zero.';
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
            ToolTip = 'Specifies that acquisition transactions in the general ledger can be in both LCY and any additional reporting currency.';
        }
        field(35; "Add.-Curr. Exch. Rate - Depr."; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add.-Curr. Exch. Rate - Depr.';
            ToolTip = 'Specifies depreciation transactions in the general ledger in both LCY and any additional reporting currency.';
        }
        field(36; "Add-Curr Exch Rate -Write-Down"; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add-Curr Exch Rate -Write-Down';
            ToolTip = 'Specifies write-down transactions in the general ledger in both LCY and any additional reporting currency.';
        }
        field(37; "Add-Curr. Exch. Rate - Apprec."; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add-Curr. Exch. Rate - Apprec.';
            ToolTip = 'Specifies appreciation transactions in the general ledger in both LCY and any additional reporting currency.';
        }
        field(38; "Add-Curr. Exch Rate - Custom 1"; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add-Curr. Exch Rate - Custom 1';
            ToolTip = 'Specifies that custom 1 transactions in the general ledger can be in both LCY and any additional reporting currency.';
        }
        field(39; "Add-Curr. Exch Rate - Custom 2"; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add-Curr. Exch Rate - Custom 2';
            ToolTip = 'Specifies custom 2 transactions in the general ledger in both LCY and any additional reporting currency.';
        }
        field(40; "Add.-Curr. Exch. Rate - Disp."; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add.-Curr. Exch. Rate - Disp.';
            ToolTip = 'Specifies disposal transactions in the general ledger in both LCY and any additional reporting currency.';
        }
        field(41; "Add.-Curr. Exch. Rate - Maint."; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Add.-Curr. Exch. Rate - Maint.';
            ToolTip = 'Specifies maintenance transactions in the general ledger in both LCY and any additional reporting currency.';
        }
        field(42; "Use Default Dimension"; Boolean)
        {
            Caption = 'Use Default Dimension';
        }
        field(43; "Subtract Disc. in Purch. Inv."; Boolean)
        {
            Caption = 'Subtract Disc. in Purch. Inv.';
            ToolTip = 'Specifies that the line and invoice discount are subtracted from the acquisition cost posted for the fixed asset.';
        }
        field(44; "Allow Correction of Disposal"; Boolean)
        {
            Caption = 'Allow Correction of Disposal';
            ToolTip = 'Specifies whether to correct fixed ledger entries of the Disposal type.';
        }
        field(45; "Allow more than 360/365 Days"; Boolean)
        {
            Caption = 'Allow more than 360/365 Days';
            ToolTip = 'Specifies if the fiscal year has more than 360 depreciation days.';
        }
        field(46; "VAT on Net Disposal Entries"; Boolean)
        {
            Caption = 'VAT on Net Disposal Entries';
            ToolTip = 'Specifies whether you sell a fixed asset with the net disposal method.';
        }
        field(47; "Allow Acq. Cost below Zero"; Boolean)
        {
            Caption = 'Allow Acq. Cost below Zero';
        }
        field(48; "Allow Identical Document No."; Boolean)
        {
            Caption = 'Allow Identical Document No.';
            ToolTip = 'Specifies the check box for this field to allow identical document numbers in the depreciation book.';
        }
        field(49; "Fiscal Year 365 Days"; Boolean)
        {
            Caption = 'Fiscal Year 365 Days';
            ToolTip = 'Specifies that when the Calculate Depreciation batch job calculates depreciations, a standardized year of 360 days, where each month has 30 days, is used.';

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
        field(50; "Use Bonus Depreciation"; Boolean)
        {
            Caption = 'Use Bonus Depreciation';
            ToolTip = 'Specifies if the bonus depreciation should be used in this book.';

            trigger OnValidate()
            var
                FASetup: Record "FA Setup";
            begin
                if Rec."Use Bonus Depreciation" then begin
                    FASetup.Get();
                    FASetup.TestField("Bonus Depreciation %");
                    FASetup.TestField("Bonus Depr. Effective Date");
                end;
                if GuiAllowed() then
                    Message(BonusDepreciationOnboardingMsg)
            end;
        }
        field(10500; "Use Accounting Period"; Boolean)
        {
            Caption = 'Use Accounting Period';
            ToolTip = 'Specifies if you want the periods between start date and ending date to correspond to the accounting periods that you have set up.';

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
        field(10800; "Derogatory Calculation"; Code[10])
        {
            Caption = 'Derogatory Calculation';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            var
                DeprBook: Record "Depreciation Book";
                FADeprBook: Record "FA Depreciation Book";
            begin
                if ("Derogatory Calculation" <> xRec."Derogatory Calculation") then begin
                    if xRec."Derogatory Calculation" <> '' then begin
                        FADeprBook.SetRange("Depreciation Book Code", xRec."Derogatory Calculation");
                        if FADeprBook.Find('-') then
                            repeat
                                FADeprBook.CalcFields(Derogatory);
                                FADeprBook.TestField(Derogatory, 0);
                            until FADeprBook.Next() = 0;
                    end else begin
                        DeprBook.SetRange("Derogatory Calculation", "Derogatory Calculation");
                        if DeprBook.Find('-') then
                            if DeprBook.Code <> Code then
                                Error(Text10802, "Derogatory Calculation", DeprBook.Code);
                        DeprBook.SetRange("Derogatory Calculation");
                        DeprBook.SetRange(Code, "Derogatory Calculation");
                        if DeprBook.Find('-') then
                            if (DeprBook."Derogatory Calculation" <> '') then
                                Error(Text10804, "Derogatory Calculation");
                    end;
                    if ("Derogatory Calculation" <> xRec."Derogatory Calculation") then
                        if "Used with Derogatory Book" <> '' then
                            Error(Text10800, Code);

                end;


                if "Derogatory Calculation" = Code then
                    Error(Text10801, "Derogatory Calculation", Code);

                CheckIntegrationFields();
            end;
        }
        field(10801; "Used with Derogatory Book"; Code[10])
        {
            CalcFormula = lookup("Depreciation Book".Code where("Derogatory Calculation" = field(Code)));
            Caption = 'Used with Derogatory Book';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10802; "G/L Integration - Derogatory"; Boolean)
        {
            Caption = 'G/L Integration - Derogatory';

            trigger OnValidate()
            begin
                CheckIntegrationFields();
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
        GLIntegration: array[13] of Boolean;
        MustBeStraightLineTxt: Label 'You cannot set %1 to %2 because some Fixed Assets associated with this book\exists where Depreciation Method is other than Straight-Line.',Comment ='%1="Use Accounting Period" Field Caption %2="Use Accounting Period" Field Value';
        Text10800: Label 'The depreciation book %1 is an accounting book and cannot be set up as a derogatory depreciation book.';
        Text10801: Label 'The depreciation book %1 cannot be set up as derogatory for depreciation book %2.';
        Text10802: Label 'The depreciation book %1 is already set up in combination with derogatory depreciation book %2.';
        Text10803: Label 'Derogatory depreciation books cannot be integrated with the general ledger. Please make sure that none of the fields on the Integration tab are checked.';
        Text10804: Label 'The depreciation book %1 is a derogatory depreciation book.';
        BonusDepreciationOnboardingMsg: Label 'This change will take effect only for the fixed asset depreciation books that are newly created with this depreciation book.';

#pragma warning disable AA0074
        Text000: Label 'The book cannot be deleted because it is in use.';
#pragma warning disable AA0470
        Text001: Label 'The book cannot be deleted because %1 %2 = %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        FAPostingTypeSetup: Record "FA Posting Type Setup";

    procedure IndexGLIntegration(var GLIntegration: array[13] of Boolean)
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
        GLIntegration[13] := "G/L Integration - Derogatory";
    end;

    [Scope('OnPrem')]
    procedure CheckIntegrationFields()
    var
        i: Integer;
    begin
        if "Derogatory Calculation" <> '' then begin
            IndexGLIntegration(GLIntegration);
            for i := 1 to 13 do
                if GLIntegration[i] then
                    Error(Text10803);
        end;
    end;

    [Scope('OnPrem')]
    procedure IsDerogatoryBook(): Boolean
    begin
        exit("Derogatory Calculation" <> '');
    end;

    local procedure GetCurrencyCode(): Code[10]
    begin
        exit('');
    end;
}

