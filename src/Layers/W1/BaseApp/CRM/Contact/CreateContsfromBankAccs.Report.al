// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Setup;

report 5193 "Create Conts. from Bank Accs."
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Create Contacts from Bank Accounts';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            RequestFilterFields = "No.", "Search Name", "Bank Acc. Posting Group", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1);

                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::"Bank Account");
                ContBusRel.SetRange("No.", "Bank Account"."No.");
                if ContBusRel.FindFirst() then
                    CurrReport.Skip();

                Cont.Init();
                Cont.TransferFields("Bank Account");
                Cont."No." := '';
                OnBeforeSetSkipDefaults("Bank Account", Cont);
                Cont.SetSkipDefault();
                Cont.Insert(true);
                DuplMgt.MakeContIndex(Cont);

                if not DuplicateContactExist then
                    DuplicateContactExist := DuplMgt.DuplicateExist(Cont);

                ContBusRel.Init();
                ContBusRel."Contact No." := Cont."No.";
                ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Bank Accs.";
                ContBusRel."Link to Table" := ContBusRel."Link to Table"::"Bank Account";
                ContBusRel."No." := "Bank Account"."No.";
                ContBusRel.Insert();
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();

                if DuplicateContactExist then
                    DuplMgt.Notify();
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000 + Text001, "No.");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Bank Accs.");
    end;

    var
        RMSetup: Record "Marketing Setup";
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        DuplMgt: Codeunit DuplicateManagement;
        Window: Dialog;
        DuplicateContactExist: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Processing vendors...\\';
#pragma warning disable AA0470
        Text001: Label 'Bank Account No.  #1##########';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSkipDefaults(var BankAccount: Record "Bank Account"; var Contact: Record Contact)
    begin
    end;
}

