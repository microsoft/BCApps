// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Setup;
using Microsoft.Purchases.Vendor;

report 5194 "Create Conts. from Vendors"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Create Contacts from Vendors';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1);

                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
                ContBusRel.SetRange("No.", Vendor."No.");
                if ContBusRel.FindFirst() then
                    CurrReport.Skip();

                Cont.Init();
                Cont.TransferFields(Vendor);
                Cont."No." := '';
                OnBeforeSetSkipDefaults(Vendor, Cont);
                Cont.SetSkipDefault();
                OnBeforeContactInsert(Vendor, Cont);
                Cont.Insert(true);
                DuplMgt.MakeContIndex(Cont);

                if not DuplicateContactExist then
                    DuplicateContactExist := DuplMgt.DuplicateExist(Cont);

                ContBusRel.Init();
                ContBusRel."Contact No." := Cont."No.";
                ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Vendors";
                ContBusRel."Link to Table" := ContBusRel."Link to Table"::Vendor;
                ContBusRel."No." := Vendor."No.";
                ContBusRel.Insert();

                InsertNewContactIfNeeded(Vendor);
                Modify(true);
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
    var
        cnt: Integer;
    begin
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Vendors");
        cnt := Vendor.Count();
        if GuiAllowed then
            if cnt > 100 then
                if not Confirm(StrSubstNo(TooManyRecordsQst, cnt)) then
                    CurrReport.Quit();
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
        Text001: Label 'Vendor No.      #1##########';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TooManyRecordsQst: Label 'This process will take several minutes because it involves %1 vendors. It is recommended that you schedule the process to run as a background task.\\Do you want to start the process immediately anyway?', Comment = '%1 = number of records';

    local procedure InsertNewContactIfNeeded(var Vendor: Record Vendor)
    var
        VendContUpdate: Codeunit "VendCont-Update";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertNewContactIfNeeded(ContBusRel, Vendor, IsHandled);
        if IsHandled then
            exit;

        if Vendor.Contact = '' then
            Vendor."Primary Contact No." := Cont."No."
        else
            VendContUpdate.InsertNewContactPerson(Vendor, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactInsert(Vendor: Record Vendor; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewContactIfNeeded(ContactBusinessRelation: Record "Contact Business Relation"; var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSkipDefaults(var Vendor: Record Vendor; var Contact: Record Contact)
    begin
    end;
}

