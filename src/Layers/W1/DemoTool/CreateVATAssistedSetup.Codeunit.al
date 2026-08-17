codeunit 101326 "Create VAT Assisted Setup"
{

    trigger OnRun()
    begin
        AddVatBusPostingGrp();
        AddVatProdPostingGrp();
        UpdateAccountsVatRates();
    end;

    local procedure AddVatProdPostingGrp()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        if not VATProductPostingGroup.FindSet() then
            exit;
        VATSetupPostingGroups.DeleteAll();

        repeat
            VATSetupPostingGroups.AddOrUpdateProdPostingGrp(
              VATProductPostingGroup.Code, VATProductPostingGroup.Description, 0, '', '', false, true);
        until VATProductPostingGroup.Next() = 0;
    end;

    local procedure AddVatBusPostingGrp()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
    begin
        if not VATBusinessPostingGroup.FindSet() then
            exit;
        VATAssistedSetupBusGrp.DeleteAll();

        repeat
            VATAssistedSetupBusGrp.InsertBusPostingGrp(VATBusinessPostingGroup.Code, VATBusinessPostingGroup.Description, true);
        until VATBusinessPostingGroup.Next() = 0;
    end;

    local procedure UpdateAccountsVatRates()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        if not VATPostingSetup.FindSet() then
            exit;

        repeat
            if VATPostingSetup."VAT Prod. Posting Group" <> '' then
                VATSetupPostingGroups.AddOrUpdateProdPostingGrp(VATPostingSetup."VAT Prod. Posting Group",
                  VATPostingSetup.Description, VATPostingSetup."VAT %", VATPostingSetup."Sales VAT Account",
                  VATPostingSetup."Purchase VAT Account", VATPostingSetup."EU Service", true);
        until VATPostingSetup.Next() = 0;
    end;
}

