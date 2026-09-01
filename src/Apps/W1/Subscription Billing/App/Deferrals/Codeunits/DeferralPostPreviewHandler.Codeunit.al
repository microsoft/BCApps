namespace Microsoft.SubscriptionBilling;

codeunit 8077 "Deferral Post. Preview Handler"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        TempCustSubContractDeferral: Record "Cust. Sub. Contract Deferral" temporary;
        TempVendSubContractDeferral: Record "Vend. Sub. Contract Deferral" temporary;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Sub. Contract Deferral", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertCustContractDeferral(var Rec: Record "Cust. Sub. Contract Deferral"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if TempCustSubContractDeferral.Get(Rec."Entry No.") then
            exit;

        TempCustSubContractDeferral := Rec;
        TempCustSubContractDeferral.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Sub. Contract Deferral", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyCustContractDeferral(var Rec: Record "Cust. Sub. Contract Deferral"; var xRec: Record "Cust. Sub. Contract Deferral"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempCustSubContractDeferral := Rec;
        if not TempCustSubContractDeferral.Insert() then
            TempCustSubContractDeferral.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vend. Sub. Contract Deferral", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertVendContractDeferral(var Rec: Record "Vend. Sub. Contract Deferral"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if TempVendSubContractDeferral.Get(Rec."Entry No.") then
            exit;

        TempVendSubContractDeferral := Rec;
        TempVendSubContractDeferral.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vend. Sub. Contract Deferral", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyVendContractDeferral(var Rec: Record "Vend. Sub. Contract Deferral"; var xRec: Record "Vend. Sub. Contract Deferral"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempVendSubContractDeferral := Rec;
        if not TempVendSubContractDeferral.Insert() then
            TempVendSubContractDeferral.Modify();
    end;

    procedure DeleteAll()
    begin
        TempCustSubContractDeferral.Reset();
        TempCustSubContractDeferral.DeleteAll();
        TempVendSubContractDeferral.Reset();
        TempVendSubContractDeferral.DeleteAll();
    end;

    procedure GetTempCustContractDeferral(var OutTempCustSubContractDeferral: Record "Cust. Sub. Contract Deferral" temporary)
    begin
        OutTempCustSubContractDeferral.Copy(TempCustSubContractDeferral, true);
    end;

    procedure GetTempVendContractDeferral(var OutTempVendSubContractDeferral: Record "Vend. Sub. Contract Deferral" temporary)
    begin
        OutTempVendSubContractDeferral.Copy(TempVendSubContractDeferral, true);
    end;
}
