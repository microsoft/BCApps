// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Stores finance charge terms configuration including interest rates, grace periods, and fee settings.
/// </summary>
table 5 "Finance Charge Terms"
{
    Caption = 'Finance Charge Terms';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Finance Charge Terms";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique code identifying the finance charge terms.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// Specifies the default interest rate percentage used to calculate finance charges on overdue amounts.
        /// </summary>
        field(2; "Interest Rate"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Interest Rate';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                FinChrgInterestRate.Reset();
                FinChrgInterestRate.SetRange("Fin. Charge Terms Code", Code);
                if not FinChrgInterestRate.IsEmpty() then
                    Message(InterestRateNotificationMsg);
            end;
        }
        /// <summary>
        /// Specifies the minimum finance charge amount in local currency that must be reached before a memo is issued.
        /// </summary>
        field(3; "Minimum Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Minimum Amount (LCY)';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the fixed additional fee amount in local currency charged on each finance charge memo.
        /// </summary>
        field(5; "Additional Fee (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Additional Fee (LCY)';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies a description of the finance charge terms for identification purposes.
        /// </summary>
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Specifies the method used to calculate interest, such as average daily balance or balance due.
        /// </summary>
        field(8; "Interest Calculation Method"; Enum "Interest Calculation Method")
        {
            Caption = 'Interest Calculation Method';
        }
        /// <summary>
        /// Specifies the number of days that define one interest calculation period for the average daily balance method.
        /// </summary>
        field(9; "Interest Period (Days)"; Integer)
        {
            Caption = 'Interest Period (Days)';
        }
        /// <summary>
        /// Specifies the grace period after the due date before interest charges begin to accrue.
        /// </summary>
        field(10; "Grace Period"; DateFormula)
        {
            Caption = 'Grace Period';
        }
        /// <summary>
        /// Specifies the formula used to calculate the due date of the finance charge memo from the document date.
        /// </summary>
        field(11; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
        }
        /// <summary>
        /// Specifies whether interest is calculated on open entries, closed entries, or all entries.
        /// </summary>
        field(12; "Interest Calculation"; Option)
        {
            Caption = 'Interest Calculation';
            OptionCaption = 'Open Entries,Closed Entries,All Entries';
            OptionMembers = "Open Entries","Closed Entries","All Entries";
        }
        /// <summary>
        /// Indicates whether calculated interest amounts should be posted to the general ledger when the memo is issued.
        /// </summary>
        field(13; "Post Interest"; Boolean)
        {
            Caption = 'Post Interest';
            InitValue = true;
        }
        /// <summary>
        /// Indicates whether the additional fee should be posted to the general ledger when the memo is issued.
        /// </summary>
        field(14; "Post Additional Fee"; Boolean)
        {
            Caption = 'Post Additional Fee';
            InitValue = true;
        }
        /// <summary>
        /// Specifies the template text used to describe individual charge lines on the finance charge memo.
        /// </summary>
        field(15; "Line Description"; Text[100])
        {
            Caption = 'Line Description';
        }
        /// <summary>
        /// Indicates whether line fees from reminders should be included in the interest calculation base.
        /// </summary>
        field(16; "Add. Line Fee in Interest"; Boolean)
        {
            Caption = 'Add. Line Fee in Interest';
        }
        /// <summary>
        /// Specifies the template text used to describe detailed interest rate entries when multiple rates apply.
        /// </summary>
        field(30; "Detailed Lines Description"; Text[100])
        {
            Caption = 'Detailed Lines Description';
        }
#if not CLEANSCHEMA26
        field(3010590; "Multiple Lines Description"; Text[50])
        {
            Caption = 'Multiple Lines Description';
            ObsoleteReason = 'Use "Detailed Lines Description" field instead.';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
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
        fieldgroup(DropDown; "Code", Description, "Interest Rate")
        {
        }
    }

    trigger OnDelete()
    begin
        FinChrgText.SetRange("Fin. Charge Terms Code", Code);
        FinChrgText.DeleteAll();

        CurrForFinChrgTerms.SetRange("Fin. Charge Terms Code", Code);
        CurrForFinChrgTerms.DeleteAll();

        FinChrgInterestRate.SetRange("Fin. Charge Terms Code", Code);
        FinChrgInterestRate.DeleteAll();
    end;

    var
        FinChrgText: Record "Finance Charge Text";
        CurrForFinChrgTerms: Record "Currency for Fin. Charge Terms";
        FinChrgInterestRate: Record "Finance Charge Interest Rate";

        InterestRateNotificationMsg: Label 'This interest rate will only be used if no relevant interest rate per date has been entered.';
}

