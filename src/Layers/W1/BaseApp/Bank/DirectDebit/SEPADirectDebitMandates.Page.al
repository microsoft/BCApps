// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

/// <summary>
/// Manages SEPA direct debit mandates that authorize automated payment collection from customers.
/// Provides functionality to create, edit, and maintain mandate information including validity periods,
/// payment types, and customer bank account associations.
/// </summary>
page 1230 "SEPA Direct Debit Mandates"
{
    Caption = 'Direct Debit Mandates';
    DataCaptionFields = ID, "Customer No.", "Customer Bank Account Code";
    PageType = List;
    SourceTable = "SEPA Direct Debit Mandate";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = Suite;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Customer Bank Account Code"; Rec."Customer Bank Account Code")
                {
                    ApplicationArea = Suite;
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = Suite;
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = Suite;
                }
                field("Date of Signature"; Rec."Date of Signature")
                {
                    ApplicationArea = Suite;
                }
                field("Type of Payment"; Rec."Type of Payment")
                {
                    ApplicationArea = Suite;
                }
                field("Expected Number of Debits"; Rec."Expected Number of Debits")
                {
                    ApplicationArea = Suite;
                }
                field("Ignore Expected Number of Debits"; Rec."Ignore Exp. Number of Debits")
                {
                    ApplicationArea = Suite;
                }
                field("Debit Counter"; Rec."Debit Counter")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Suite;
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control14; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control15; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec."Customer No." = '' then
            if Rec.GetFilter("Customer No.") <> '' then
                Rec.Validate("Customer No.", Rec.GetRangeMin("Customer No."));
        if Rec."Customer Bank Account Code" = '' then
            if Rec.GetFilter("Customer Bank Account Code") <> '' then
                Rec.Validate("Customer Bank Account Code", Rec.GetRangeMin("Customer Bank Account Code"));
    end;
}

