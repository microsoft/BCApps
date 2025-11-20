// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

page 9153 "My Accounts"
{
    Caption = 'My Accounts';
    PageType = ListPart;
    SourceTable = "My Account";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account number.';

                    trigger OnValidate()
                    begin
                        SyncFieldsWithGLAccount();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the name of the G/L account.';
                }
                field(Balance; Rec."Acc. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the balance of the G/L account.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = ViewDetails;
                RunObject = Page "G/L Account Card";
                RunPageLink = "No." = field("Account No.");
                RunPageMode = View;
                RunPageView = sorting("No.");
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SyncFieldsWithGLAccount();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId());
    end;

    local procedure SyncFieldsWithGLAccount()
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLAccount: Record "G/L Account";
        SyncFieldsUpdatedInGLAccount: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSyncFieldsWithGLAccount(Rec, IsHandled);
        if IsHandled then
            exit;

        GLAccount.ReadIsolation(IsolationLevel::ReadCommitted);
        GLAccount.SetLoadFields("Name", Totaling);
        if GLAccount.Get(Rec."Account No.") then begin
            SyncFieldsUpdatedInGLAccount := CalcSyncFieldsUpdatedInGLAccount(GLAccount);
            OnSyncFieldsWithGLAccountOnAfterCalcFields(GLAccount, SyncFieldsUpdatedInGLAccount);
            if SyncFieldsUpdatedInGLAccount then begin
                Rec.Name := GLAccount.Name;
                Rec.Totaling := GLAccount.Totaling;
                if not IsNullGuid(Rec.SystemId) then begin
                    Rec.Modify();
                    Rec.CalcFields("Acc. Balance");
                end;
            end;
        end;
    end;

    local procedure CalcSyncFieldsUpdatedInGLAccount(var GLAccount: Record "G/L Account"): Boolean
    begin
        exit((Rec.Name <> GLAccount.Name) or (Rec.Totaling <> GLAccount.Totaling));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSyncFieldsWithGLAccount(var MyAccount: Record "My Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSyncFieldsWithGLAccountOnAfterCalcFields(var GLAccount: Record "G/L Account"; var SyncFieldsUpdatedInGLAccount: Boolean)
    begin
    end;
}

