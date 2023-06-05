codeunit 4885 "EU3 VAT Stat. Subscribers"
{
    Access = Internal;

    Permissions = tabledata "VAT Entry" = r,
                  tabledata "VAT Statement Line" = r;

    [EventSubscriber(ObjectType::Page, Page::"VAT Statement Preview Line", 'OnBeforeOpenPageVATEntryTotaling', '', false, false)]
    local procedure OnBeforeOpenPageVATEntryTotaling(var VATEntry: Record "VAT Entry"; var VATStatementLine: Record "VAT Statement Line"; var GLEntry: Record "G/L Entry")
    var
#if not CLEAN23
        EU3PartyTradeFeatureMgt: Codeunit "EU3 Party Trade Feature Mgt.";
#endif
    begin
#if not CLEAN23
        if not EU3PartyTradeFeatureMgt.IsEnabled() then
            exit;
# endif
        VATEntry.SetRange("EU 3-Party Trade", VATStatementLine."EU 3 Party Trade");
    end;

    [EventSubscriber(ObjectType::Report, Report::"VAT Statement", 'OnCalcLineTotalOnVATEntryTotalingOnAfterVATEntrySetFilters', '', false, false)]
    local procedure OnCalcLineTotalOnVATEntryTotalingOnAfterVATEntrySetFilters(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; Selection: Enum "VAT Statement Report Selection")
    var
#if not CLEAN23
        EU3PartyTradeFeatureMgt: Codeunit "EU3 Party Trade Feature Mgt.";
#endif
    begin
#if not CLEAN23
        if not EU3PartyTradeFeatureMgt.IsEnabled() then
            exit;
# endif
        VATEntry.SetRange("EU 3-Party Trade", VATStmtLine."EU 3 Party Trade");
    end;
}