// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Foundation.Period;
using Microsoft.Intercompany.Partner;
using Microsoft.Sales.Receivables;
using System.Utilities;

/// <summary>
/// Extends Customer with Intercompany-specific fields and logic.
/// </summary>
tableextension 8469 ICCustomer extends Customer
{
    fields
    {
        /// <summary>
        /// Specifies the intercompany partner code for transactions between related companies.
        /// </summary>
        field(119; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the customer''s intercompany partner code.';
            TableRelation = "IC Partner";

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                AccountingPeriod: Record "Accounting Period";
                ICPartner: Record "IC Partner";
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if xRec."IC Partner Code" <> "IC Partner Code" then begin
                    if not CustLedgEntry.SetCurrentKey("Customer No.", Open) then
                        CustLedgEntry.SetCurrentKey("Customer No.");
                    CustLedgEntry.SetRange("Customer No.", "No.");
                    CustLedgEntry.SetRange(Open, true);
                    if CustLedgEntry.FindLast() then
                        Error(OpenEntriesErr, FieldCaption("IC Partner Code"), TableCaption);

                    CustLedgEntry.Reset();
                    CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                    CustLedgEntry.SetRange("Customer No.", "No.");
                    AccountingPeriod.SetRange(Closed, false);
                    if AccountingPeriod.FindFirst() then begin
                        CustLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
                        if CustLedgEntry.FindFirst() then
                            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(EntriesInOpenPeriodQst, TableCaption), true) then
                                "IC Partner Code" := xRec."IC Partner Code";
                    end;
                end;

                if "IC Partner Code" <> '' then begin
                    ICPartner.Get("IC Partner Code");
                    if (ICPartner."Customer No." <> '') and (ICPartner."Customer No." <> "No.") then
                        Error(AlreadyAssignedErr, FieldCaption("IC Partner Code"), "IC Partner Code", TableCaption(), ICPartner."Customer No.");
                    ICPartner."Customer No." := "No.";
                    ICPartner.Modify();
                end;

                if (xRec."IC Partner Code" <> "IC Partner Code") and ICPartner.Get(xRec."IC Partner Code") then begin
                    ICPartner."Customer No." := '';
                    ICPartner.Modify();
                end;
            end;
        }
    }

    keys
    {
        key(Key22; "IC Partner Code")
        {
        }
    }

    var
        AlreadyAssignedErr: Label 'The %1 %2 has been assigned to %3 %4.\The same %1 cannot be entered on more than one %3. Enter another code.', Comment = '%1 = field caption (IC Partner Code), %2 = IC Partner Code value, %3 = table caption (Customer), %4 = customer number';
        EntriesInOpenPeriodQst: Label 'Reconciling IC transactions may be difficult if you change IC Partner Code because this %1 has ledger entries in a fiscal year that has not yet been closed.\ Do you still want to change the IC Partner Code?', Comment = '%1 = table caption (Customer)';
        OpenEntriesErr: Label 'You cannot change the contents of the %1 field because this %2 has one or more open ledger entries.', Comment = '%1 = field caption (IC Partner Code), %2 = table caption (Customer)';
}
