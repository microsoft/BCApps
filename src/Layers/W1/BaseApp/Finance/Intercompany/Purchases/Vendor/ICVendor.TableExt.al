// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Foundation.Period;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Payables;
using System.Utilities;

/// <summary>
/// Extends Vendor with Intercompany-specific fields and logic.
/// </summary>
tableextension 8447 ICVendor extends Vendor
{
    fields
    {
        field(119; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the vendor''s intercompany partner code.';
            TableRelation = "IC Partner";

            trigger OnValidate()
            var
                VendLedgEntry: Record "Vendor Ledger Entry";
                AccountingPeriod: Record "Accounting Period";
                ICPartner: Record "IC Partner";
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if xRec."IC Partner Code" <> "IC Partner Code" then begin
                    if not VendLedgEntry.SetCurrentKey("Vendor No.", Open) then
                        VendLedgEntry.SetCurrentKey("Vendor No.");
                    VendLedgEntry.SetRange("Vendor No.", "No.");
                    VendLedgEntry.SetRange(Open, true);
                    if VendLedgEntry.FindLast() then
                        Error(OpenEntriesErr, FieldCaption("IC Partner Code"), TableCaption);

                    VendLedgEntry.Reset();
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
                    VendLedgEntry.SetRange("Vendor No.", "No.");
                    AccountingPeriod.SetRange(Closed, false);
                    if AccountingPeriod.FindFirst() then begin
                        VendLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
                        if VendLedgEntry.FindFirst() then
                            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(EntriesInOpenPeriodQst, TableCaption), true) then
                                "IC Partner Code" := xRec."IC Partner Code";
                    end;
                end;

                if "IC Partner Code" <> '' then begin
                    ICPartner.Get("IC Partner Code");
                    if (ICPartner."Vendor No." <> '') and (ICPartner."Vendor No." <> "No.") then
                        Error(AlreadyAssignedErr, FieldCaption("IC Partner Code"), "IC Partner Code", TableCaption(), ICPartner."Vendor No.");
                    ICPartner."Vendor No." := "No.";
                    ICPartner.Modify();
                end;

                if (xRec."IC Partner Code" <> "IC Partner Code") and ICPartner.Get(xRec."IC Partner Code") then begin
                    ICPartner."Vendor No." := '';
                    ICPartner.Modify();
                end;
            end;
        }
    }

    keys
    {
        key(Key21; "IC Partner Code")
        {
        }
    }

    var
        AlreadyAssignedErr: Label 'The %1 %2 has been assigned to %3 %4.\The same %1 cannot be entered on more than one %3.', Comment = '%1 = field caption, %2 = field value, %3 = table caption, %4 = vendor number';
        EntriesInOpenPeriodQst: Label 'Reconciling IC transactions may be difficult if you change IC Partner Code because this %1 has ledger entries in a fiscal year that has not yet been closed.\ Do you still want to change the IC Partner Code?', Comment = '%1 = table caption';
        OpenEntriesErr: Label 'You cannot change the contents of the %1 field because this %2 has one or more open ledger entries.', Comment = '%1 = field caption, %2 = table caption';
}
