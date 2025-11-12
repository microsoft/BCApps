// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Duplicates;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;
using System.Environment.Configuration;

codeunit 5060 DuplicateManagement
{
    Permissions = tabledata "Marketing Setup" = r,
                  tabledata "Contact Duplicate" = rid,
                  tabledata "Cont. Duplicate Search String" = rid,
                  tabledata "Duplicate Search String Setup" = r;

    trigger OnRun()
    begin
    end;

    var
        RMSetup: Record "Marketing Setup";

#pragma warning disable AA0074
        Text000: Label 'Duplicate Contacts were found. Would you like to process these?';
#pragma warning restore AA0074
        DuplicateContactExistMsg: Label 'There are duplicate contacts.';
        OpenContactDuplicatesPageLbl: Label 'Show';

    procedure MakeContIndex(Cont: Record Contact)
    var
        DuplSearchStringSetup: Record "Duplicate Search String Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnMakeContIndex(Cont, IsHandled);
        if IsHandled then
            exit;

        RMSetup.Get();

        RemoveContIndex(Cont, true);

        if DuplSearchStringSetup.Find('-') then
            repeat
                InsDuplContIndex(Cont, DuplSearchStringSetup);
            until DuplSearchStringSetup.Next() = 0;

        IsHandled := false;
        OnMakeContIndexOnBeforeInsDuplCont(Cont, IsHandled);
        if not IsHandled then
            InsDuplCont(Cont, RMSetup."Search Hit %");
    end;

    procedure RemoveContIndex(Cont: Record Contact; KeepAccepted: Boolean)
    var
        DuplContSearchString: Record "Cont. Duplicate Search String";
        ContactDuplicate: Record "Contact Duplicate";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRemoveContIndex(Cont, KeepAccepted, IsHandled);
        if IsHandled then
            exit;

        DuplContSearchString.SetRange("Contact Company No.", Cont."No.");
        if DuplContSearchString.FindFirst() then
            DuplContSearchString.DeleteAll();

        ContactDuplicate.FilterGroup(-1);
        ContactDuplicate.SetRange("Contact No.", Cont."No.");
        ContactDuplicate.SetRange("Duplicate Contact No.", Cont."No.");
        ContactDuplicate.FilterGroup(0);
        if KeepAccepted then
            ContactDuplicate.SetRange("Separate Contacts", false);
        ContactDuplicate.DeleteAll(true);
    end;

    procedure DuplicateExist(Cont: Record Contact) Result: Boolean
    var
        ContactDuplicate: Record "Contact Duplicate";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDuplicateExist(Cont, Result, IsHandled);
        if IsHandled then
            exit(Result);

        RMSetup.Get();
        if not RMSetup."Autosearch for Duplicates" then
            exit(false);
        ContactDuplicate.FilterGroup(-1);
        ContactDuplicate.SetRange("Contact No.", Cont."No.");
        ContactDuplicate.SetRange("Duplicate Contact No.", Cont."No.");
        ContactDuplicate.FilterGroup(0);
        ContactDuplicate.SetRange("Separate Contacts", false);
        exit(ContactDuplicate.Find('=<>'));
    end;

    procedure LaunchDuplicateForm(Cont: Record Contact)
    var
        ContactDuplicate: Record "Contact Duplicate";
    begin
        if Confirm(Text000, true) then begin
            ContactDuplicate.SetRange("Contact No.", Cont."No.");
            PAGE.RunModal(PAGE::"Contact Duplicates", ContactDuplicate);
        end
    end;

    local procedure InsDuplContIndex(Cont: Record Contact; DuplSearchStringSetup: Record "Duplicate Search String Setup")
    var
        DuplContSearchString: Record "Cont. Duplicate Search String";
        ContactRecRef: RecordRef;
    begin
        ContactRecRef.GetTable(Cont);

        DuplContSearchString.Init();
        DuplContSearchString."Contact Company No." := Cont."No.";
        DuplContSearchString."Field No." := DuplSearchStringSetup."Field No.";
        DuplContSearchString."Part of Field" := DuplSearchStringSetup."Part of Field";
        DuplContSearchString."Search String" :=
          ComposeIndexString(
            ContactRecRef, DuplContSearchString."Field No.",
            DuplSearchStringSetup."Part of Field", DuplSearchStringSetup.Length);

        OnInsDuplContIndexOnBeforeDuplContSearchStringInsert(Cont, DuplContSearchString, DuplSearchStringSetup);
        if DuplContSearchString."Search String" <> '' then
            DuplContSearchString.Insert();
    end;

    local procedure InsDuplCont(Cont: Record Contact; HitRatio: Integer)
    var
        DuplContSearchString: Record "Cont. Duplicate Search String";
        DuplContSearchString2: Record "Cont. Duplicate Search String";
        TempContactDuplicate: Record "Contact Duplicate" temporary;
        DuplCont2: Record "Contact Duplicate";
        DuplSearchStringSetup: Record "Duplicate Search String Setup";
    begin
        DuplContSearchString.SetRange("Contact Company No.", Cont."No.");
        if DuplContSearchString.Find('-') then
            repeat
                DuplContSearchString2.SetCurrentKey("Field No.", "Part of Field", "Search String");
                DuplContSearchString2.SetRange("Field No.", DuplContSearchString."Field No.");
                DuplContSearchString2.SetRange("Part of Field", DuplContSearchString."Part of Field");
                DuplContSearchString2.SetRange("Search String", DuplContSearchString."Search String");
                DuplContSearchString2.SetFilter("Contact Company No.", '<>%1', DuplContSearchString."Contact Company No.");
                OnInsDuplContOnAfterDuplContSearchString2SetFilters(DuplContSearchString, DuplContSearchString2);
                if DuplContSearchString2.Find('-') then
                    repeat
                        if TempContactDuplicate.Get(DuplContSearchString."Contact Company No.", DuplContSearchString2."Contact Company No.") then begin
                            if not TempContactDuplicate."Separate Contacts" then begin
                                TempContactDuplicate."No. of Matching Strings" := TempContactDuplicate."No. of Matching Strings" + 1;
                                TempContactDuplicate.Modify();
                            end;
                        end else begin
                            TempContactDuplicate."Contact No." := DuplContSearchString."Contact Company No.";
                            TempContactDuplicate."Duplicate Contact No." := DuplContSearchString2."Contact Company No.";
                            TempContactDuplicate."Separate Contacts" := false;
                            TempContactDuplicate."No. of Matching Strings" := 1;
                            TempContactDuplicate.Insert();
                        end;
                    until DuplContSearchString2.Next() = 0;
            until DuplContSearchString.Next() = 0;

        TempContactDuplicate.SetFilter("No. of Matching Strings", '>=%1', Round(DuplSearchStringSetup.Count * HitRatio / 100, 1, '>'));
        OnInsDuplContOnAfterDuplContSetFilters(TempContactDuplicate, DuplContSearchString, DuplSearchStringSetup);
        if TempContactDuplicate.Find('-') then begin
            repeat
                DuplCont2 := TempContactDuplicate;
                if not DuplCont2.Get(TempContactDuplicate."Contact No.", TempContactDuplicate."Duplicate Contact No.") and
                   not DuplCont2.Get(TempContactDuplicate."Duplicate Contact No.", TempContactDuplicate."Contact No.")
                then
                    DuplCont2.Insert(true);
            until TempContactDuplicate.Next() = 0;
            TempContactDuplicate.DeleteAll();
        end;
    end;

    procedure ComposeIndexString(var RecRef: RecordRef; FieldNo: Integer; "Part": Option First,Last; ChrToCopy: Integer): Text[10]
    var
        FieldRef: FieldRef;
        InString: Text[260];
    begin
        FieldRef := RecRef.Field(FieldNo);
        InString := Format(FieldRef.Value);
        InString := DelChr(InString, '=', ' +"&/,.;:-_(){}#!£$\');

        if StrLen(InString) < ChrToCopy then
            ChrToCopy := StrLen(InString);

        if ChrToCopy > 0 then
            if Part = Part::First then
                InString := CopyStr(InString, 1, ChrToCopy)
            else
                InString := CopyStr(InString, StrLen(InString) - ChrToCopy + 1, ChrToCopy);

        exit(UpperCase(InString));
    end;

    procedure Notify()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DuplicateContNotification: Notification;
        DummyRecID: RecordId;
    begin
        DuplicateContNotification.Message(DuplicateContactExistMsg);
        DuplicateContNotification.AddAction(OpenContactDuplicatesPageLbl, Codeunit::DuplicateManagement, 'RunModalContactDuplicates');
        NotificationLifecycleMgt.SendNotification(DuplicateContNotification, DummyRecID);
    end;

    procedure RunModalContactDuplicates(Notification: Notification)
    begin
        PAGE.RunModal(PAGE::"Contact Duplicates");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRemoveContIndex(Contact: Record Contact; KeepAccepted: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDuplicateExist(Contact: Record Contact; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsDuplContIndexOnBeforeDuplContSearchStringInsert(var Contact: Record Contact; var DuplContSearchString: Record "Cont. Duplicate Search String"; DuplSearchStringSetup: Record "Duplicate Search String Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsDuplContOnAfterDuplContSearchString2SetFilters(var DuplContSearchString: Record "Cont. Duplicate Search String"; var DuplContSearchString2: Record "Cont. Duplicate Search String")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsDuplContOnAfterDuplContSetFilters(var TempDuplCont: Record "Contact Duplicate" temporary; var DuplContSearchString: Record "Cont. Duplicate Search String"; var DuplSearchStringSetup: Record "Duplicate Search String Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeContIndex(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeContIndexOnBeforeInsDuplCont(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;
}

