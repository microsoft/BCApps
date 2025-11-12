// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.Currency;

table 293 "Reminder Level"
{
    Caption = 'Reminder Level';
    DataCaptionFields = "Reminder Terms Code", "No.";
    DrillDownPageID = "Reminder Levels";
    LookupPageID = "Reminder Levels";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            NotBlank = true;
            TableRelation = "Reminder Terms";
        }
        field(2; "No."; Integer)
        {
            Caption = 'No.';
            MinValue = 1;
            NotBlank = true;
        }
        field(3; "Grace Period"; DateFormula)
        {
            Caption = 'Grace Period';
        }
        field(4; "Additional Fee (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Additional Fee (LCY)';
            MinValue = 0;
        }
        field(5; "Calculate Interest"; Boolean)
        {
            Caption = 'Calculate Interest';
        }
        field(6; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
        }
        field(7; "Add. Fee per Line Amount (LCY)"; Decimal)
        {
            Caption = 'Add. Fee per Line Amount (LCY)';
            MinValue = 0;
        }
        field(8; "Add. Fee per Line Description"; Text[100])
        {
            Caption = 'Add. Fee per Line Description';
        }
        field(9; "Add. Fee Calculation Type"; Option)
        {
            Caption = 'Add. Fee Calculation Type';
            OptionCaption = 'Fixed,Single Dynamic,Accumulated Dynamic';
            OptionMembers = "Fixed","Single Dynamic","Accumulated Dynamic";
        }
        field(20; "Reminder Attachment Text"; Guid)
        {
            Caption = 'Reminder Attachment Text';
            TableRelation = "Reminder Attachment Text".Id;
        }
        field(21; "Reminder Email Text"; Guid)
        {
            Caption = 'Reminder Email Text';
            TableRelation = "Reminder Email Text".Id;
        }
    }

    keys
    {
        key(Key1; "Reminder Terms Code", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderEmailText: Record "Reminder Email Text";
    begin
        AdditionalFeeSetup.SetRange("Reminder Terms Code", "Reminder Terms Code");
        AdditionalFeeSetup.SetRange("Reminder Level No.", "No.");
        AdditionalFeeSetup.DeleteAll(true);

        ReminderText.SetRange("Reminder Terms Code", "Reminder Terms Code");
        ReminderText.SetRange("Reminder Level", "No.");
        ReminderText.DeleteAll();

        CurrencyForReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
        CurrencyForReminderLevel.SetRange("No.", "No.");
        CurrencyForReminderLevel.DeleteAll();

        ReminderAttachmentText.SetRange(Id, "Reminder Attachment Text");
        ReminderAttachmentText.DeleteAll();

        ReminderEmailText.SetRange(Id, "Reminder Email Text");
        ReminderEmailText.DeleteAll();
    end;

    trigger OnRename()
    begin
        AdditionalFeeSetup.SetRange("Reminder Terms Code", xRec."Reminder Terms Code");
        AdditionalFeeSetup.SetRange("Reminder Level No.", xRec."No.");
        while AdditionalFeeSetup.FindFirst() do
            AdditionalFeeSetup.Rename("Reminder Terms Code",
              "No.",
              AdditionalFeeSetup."Charge Per Line",
              AdditionalFeeSetup."Currency Code",
              AdditionalFeeSetup."Threshold Remaining Amount");

        ReminderText.SetRange("Reminder Terms Code", xRec."Reminder Terms Code");
        ReminderText.SetRange("Reminder Level", xRec."No.");
        while ReminderText.FindFirst() do
            ReminderText.Rename("Reminder Terms Code", "No.", ReminderText.Position, ReminderText."Line No.");

        CurrencyForReminderLevel.SetRange("Reminder Terms Code", xRec."Reminder Terms Code");
        CurrencyForReminderLevel.SetRange("No.", xRec."No.");
        while CurrencyForReminderLevel.FindFirst() do
            CurrencyForReminderLevel.Rename("Reminder Terms Code", "No.",
              CurrencyForReminderLevel."Currency Code");
    end;

    var
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
        AdditionalFeeSetup: Record "Additional Fee Setup";

    procedure CalculateAdditionalFixedFee(CurrencyCode: Code[10]; ChargePerLine: Boolean; PostingDate: Date): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        FeeAmount: Decimal;
    begin
        if CurrencyCode = '' then begin
            if ChargePerLine then
                exit("Add. Fee per Line Amount (LCY)");

            exit("Additional Fee (LCY)");
        end;

        CurrencyForReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
        CurrencyForReminderLevel.SetRange("No.", "No.");
        CurrencyForReminderLevel.SetRange("Currency Code", CurrencyCode);
        if CurrencyForReminderLevel.FindFirst() then begin
            if ChargePerLine then
                exit(CurrencyForReminderLevel."Add. Fee per Line");

            exit(CurrencyForReminderLevel."Additional Fee");
        end;
        if ChargePerLine then
            FeeAmount := "Add. Fee per Line Amount (LCY)"
        else
            FeeAmount := "Additional Fee (LCY)";
        exit(CurrExchRate.ExchangeAmtLCYToFCY(
            PostingDate, CurrencyCode,
            FeeAmount,
            CurrExchRate.ExchangeRate(PostingDate, CurrencyCode)));
    end;

    procedure NewRecord()
    begin
        ReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
        if ReminderLevel.FindLast() then
            "No." := ReminderLevel."No.";
        "No." += 1;
    end;

    procedure GetAdditionalFee(RemainingAmount: Decimal; CurrencyCode: Code[10]; ChargePerLine: Boolean; PostingDate: Date): Decimal
    var
        ReminderTerms: Record "Reminder Terms";
        AdditionalFeeSetup: Record "Additional Fee Setup";
    begin
        if not ReminderTerms.Get("Reminder Terms Code") then
            exit(0);

        case "Add. Fee Calculation Type" of
            "Add. Fee Calculation Type"::Fixed:
                exit(CalculateAdditionalFixedFee(CurrencyCode, ChargePerLine, PostingDate));
            "Add. Fee Calculation Type"::"Accumulated Dynamic":
                exit(AdditionalFeeSetup.GetAdditionalFeeFromSetup(Rec, RemainingAmount,
                    CurrencyCode, ChargePerLine, "Add. Fee Calculation Type"::"Accumulated Dynamic", PostingDate));
            "Add. Fee Calculation Type"::"Single Dynamic":
                exit(AdditionalFeeSetup.GetAdditionalFeeFromSetup(Rec, RemainingAmount,
                    CurrencyCode, ChargePerLine, "Add. Fee Calculation Type"::"Single Dynamic", PostingDate));
        end;
    end;
}

