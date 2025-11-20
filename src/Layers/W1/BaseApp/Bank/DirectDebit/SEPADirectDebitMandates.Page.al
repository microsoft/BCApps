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
                    ToolTip = 'Specifies the ID of the direct-debit mandate.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the customer that the direct-debit mandate is activated for.';
                    Visible = false;
                }
                field("Customer Bank Account Code"; Rec."Customer Bank Account Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies customer bank account that the direct-debit mandate is activated for.';
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the direct-debit mandate starts.';
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the direct-debit mandate ends.';
                }
                field("Date of Signature"; Rec."Date of Signature")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when the direct-debit mandate was signed by the customer.';
                }
                field("Type of Payment"; Rec."Type of Payment")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the direct-debit transaction is the first or the last according to the expected number of direct-debit transactions that you entered in the Expected Number of Debits field.';
                }
                field("Expected Number of Debits"; Rec."Expected Number of Debits")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how many direct-debit transactions you expect to perform using the direct-debit mandate. This field is used to calculate when to enter First or Last in the Sequence Type field in the Direct Debit Collect. Entries window.';
                }
                field("Ignore Expected Number of Debits"; Rec."Ignore Exp. Number of Debits")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the direct-debit mandate will not be closed automatically when the debit counter reaches the expected number of debits.';
                }
                field("Debit Counter"; Rec."Debit Counter")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies how many direct-debit transactions have been performed using the direct-debit mandate.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the direct-debit mandate is closed, for example because the date in the Valid To field has been exceeded.';
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

