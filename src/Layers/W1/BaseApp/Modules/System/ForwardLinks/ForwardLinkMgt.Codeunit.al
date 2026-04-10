// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

codeunit 1431 "Forward Link Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        AllowedVATDateTok: Label 'ALLOWED VAT DATE', Locked = true;
        AllowedPostingDateTok: Label 'ALLOWED POSTING DATE', Locked = true;
        UsePostingPeriodsMsg: Label 'Use posting periods to specify when users can post to the general ledger.';
        BlockedCustomerTok: Label 'BLOCKED CUSTOMER', Locked = true;
        BlockedCustomerMsg: Label 'Block Customers';
        BlockedItemTok: Label 'BLOCKED ITEM', Locked = true;
        BlockedItemMsg: Label 'Block Items from Sales or Purchasing';
        WorkingWithDimsTok: Label 'WORKING WITH DIMENSIONS', Locked = true;
        WorkingWithDimensionsMsg: Label 'Working with dimensions.';
        SalesLineDropShipmentTok: Label 'DROP SHIPMENT', Locked = true;
        SalesLineDropShipmentMsg: Label 'Making drop shipments';
        EmptySetupAccountTok: Label 'EMPTY SETUP ACCOUNT', Locked = true;
        EmptySetupAccountMsg: Label 'Empty Setup Account';
        TroubleshootingDimensionsTok: Label 'TROUBLESHOOTING DIMENSIONS', Locked = true;
        TroubleshootingDimensionsMsg: Label 'Troubleshooting and correcting dimensions';
        FinancePostingGroupsTok: Label 'FINANCE POSTING GROUPS', Locked = true;
        FinancePostingGroupsMsg: Label 'Finance posting groups';
        FinanceSetupVATTok: Label 'FINANCE SETUP VAT', Locked = true;
        FinanceSetupVATMsg: Label 'Finance setup VAT';

    procedure AddLink(NewName: Code[30]; NewDescription: Text[250]; NewLink: Text[250])
    var
        NamedForwardLink: Record "Named Forward Link";
    begin
        if not NamedForwardLink.Get(NewName) then begin
            NamedForwardLink.Init();
            NamedForwardLink.Name := NewName;
            NamedForwardLink.Description := NewDescription;
            NamedForwardLink.Link := NewLink;
            NamedForwardLink.Insert();
        end;
    end;

    procedure GetHelpCodeForAllowedVATDate(): Code[30]
    begin
        exit(AllowedVATDateTok);
    end;

    procedure GetHelpCodeForAllowedPostingDate(): Code[30]
    begin
        exit(AllowedPostingDateTok);
    end;

    procedure GetHelpCodeForEmptyPostingSetupAccount(): Code[30]
    begin
        exit(EmptySetupAccountTok);
    end;

    procedure GetHelpCodeForBlockedCustomer(): Code[30]
    begin
        exit(BlockedCustomerTok);
    end;

    procedure GetHelpCodeForBlockedItem(): Code[30]
    begin
        exit(BlockedItemTok);
    end;

    procedure GetHelpCodeForWorkingWithDimensions(): Code[30]
    begin
        exit(WorkingWithDimsTok);
    end;

    procedure GetHelpCodeForSalesLineDropShipmentErr(): Code[30]
    begin
        exit(SalesLineDropShipmentTok);
    end;

    procedure GetHelpCodeForTroubleshootingDimensions(): Code[30]
    begin
        exit(TroubleshootingDimensionsTok);
    end;

    procedure GetHelpCodeForFinancePostingGroups(): Code[30]
    begin
        exit(FinancePostingGroupsTok);
    end;

    procedure GetHelpCodeForFinanceSetupVAT(): Code[30]
    begin
        exit(FinanceSetupVATTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Named Forward Link", 'OnLoad', '', false, false)]
    local procedure OnLoadHelpArticleCodes()
    begin
        AddLink(
          GetHelpCodeForAllowedPostingDate(), UsePostingPeriodsMsg, 'https://go.microsoft.com/fwlink/?linkid=2080265');
        AddLink(
          GetHelpCodeForBlockedCustomer(), BlockedCustomerMsg, 'https://go.microsoft.com/fwlink/?linkid=2094681');
        AddLink(
          GetHelpCodeForBlockedItem(), BlockedItemMsg, 'https://go.microsoft.com/fwlink/?linkid=2094578');
        AddLink(
          GetHelpCodeForWorkingWithDimensions(), WorkingWithDimensionsMsg, 'https://go.microsoft.com/fwlink/?linkid=2079638');
        AddLink(
          GetHelpCodeForSalesLineDropShipmentErr(), SalesLineDropShipmentMsg, 'https://go.microsoft.com/fwlink/?linkid=2104945');
        AddLink(
          GetHelpCodeForEmptyPostingSetupAccount(), EmptySetupAccountMsg, 'https://go.microsoft.com/fwlink/?linkid=2157418');
        AddLink(
            GetHelpCodeForTroubleshootingDimensions(), TroubleshootingDimensionsMsg, 'https://go.microsoft.com/fwlink/?linkid=2162522');
        AddLink(
            GetHelpCodeForFinanceSetupVAT(), FinanceSetupVATMsg, 'https://go.microsoft.com/fwlink/?linkid=2185786');
        AddLink(
            GetHelpCodeForFinancePostingGroups(), FinancePostingGroupsMsg, 'https://go.microsoft.com/fwlink/?linkid=2185787');
        AddLink(
            GetHelpCodeForAllowedVATDate(), UsePostingPeriodsMsg, 'https://go.microsoft.com/fwlink/?linkid=2080265');
    end;
}

