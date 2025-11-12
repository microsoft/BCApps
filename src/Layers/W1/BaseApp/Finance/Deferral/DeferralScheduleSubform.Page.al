// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

/// <summary>
/// Subform page displaying detailed deferral schedule lines.
/// Shows individual period amounts and posting dates for a deferral schedule.
/// </summary>
page 1703 "Deferral Schedule Subform"
{
    Caption = 'Deferral Schedule Detail';
    PageType = ListPart;
    SourceTable = "Deferral Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Suite;
                }
            }
            group(Control8)
            {
                ShowCaption = false;
                group(Control7)
                {
                    ShowCaption = false;
                    field(TotalDeferral; TotalDeferral)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Total Amount to Defer';
                        Editable = false;
                        Enabled = false;
                        ToolTip = 'Specifies the total amount to defer.';
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateTotal();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Changed := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Changed := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Changed := true;
    end;

    var
        TotalDeferral: Decimal;
        Changed: Boolean;

    local procedure UpdateTotal()
    begin
        CalcTotal(Rec, TotalDeferral);
    end;

    local procedure CalcTotal(var DeferralLine: Record "Deferral Line"; var TotalDeferral: Decimal)
    var
        DeferralLineTemp: Record "Deferral Line";
        ShowTotalDeferral: Boolean;
    begin
        DeferralLineTemp.CopyFilters(DeferralLine);
        ShowTotalDeferral := DeferralLineTemp.CalcSums(Amount);
        if ShowTotalDeferral then
            TotalDeferral := DeferralLineTemp.Amount;
    end;

    /// <summary>
    /// Gets the changed status of the deferral schedule subform.
    /// </summary>
    /// <returns>True if the subform data has been modified, false otherwise</returns>
    procedure GetChanged(): Boolean
    begin
        exit(Changed);
    end;
}

