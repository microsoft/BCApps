// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Customer;
using Microsoft.Service.Setup;

codeunit 5959 "Serv. Posting Group Change"
{
    var
        CannotChangePostingGroupErr: Label 'You cannot change the value %1 to %2 because %3 has not been filled in.', Comment = '%1 = old posting group; %2 = new posting group; %3 = tablecaption of Subst. Vendor/Customer Posting Group';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Group Change", 'OnAfterChangePostingGroup', '', false, false)]
    local procedure OnAfterChangePostingGroup(SourceRecordRef: RecordRef; NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        if SourceRecordRef.Number = Database::"Service Header" then
            CheckPostingGroupChangeInServiceHeader(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckPostingGroupChangeInServiceHeader(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckCustomerPostingGroupChangeAndCustomerInService(NewPostingGroup, OldPostingGroup, '');
    end;

    local procedure CheckCustomerPostingGroupChangeAndCustomerInService(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; CustomerNo: Code[20])
    begin
        CheckAllowChangeServiceSetup();
        if not HasCustomerSamePostingGroup(NewPostingGroup, CustomerNo) then
            CheckCustomerPostingGroupSubstSetup(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckCustomerPostingGroupSubstSetup(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    var
        AltCustomerPostingGroup: Record "Alt. Customer Posting Group";
    begin
        if not AltCustomerPostingGroup.Get(OldPostingGroup, NewPostingGroup) then
            Error(CannotChangePostingGroupErr, OldPostingGroup, NewPostingGroup, AltCustomerPostingGroup.TableCaption());
    end;

    local procedure HasCustomerSamePostingGroup(NewPostingGroup: Code[20]; CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            exit(NewPostingGroup = Customer."Customer Posting Group");
        exit(false);
    end;

    procedure CheckAllowChangeServiceSetup()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.TestField("Allow Multiple Posting Groups");
        ServiceMgtSetup.TestField("Check Multiple Posting Groups", "Posting Group Change Method"::"Alternative Groups");
    end;

}
