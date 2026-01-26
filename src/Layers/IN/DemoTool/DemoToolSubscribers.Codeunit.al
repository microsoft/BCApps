codeunit 101440 "Demo Tool Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeValidateVATProdPostingGroup', '', false, false)]
    local procedure OnBeforeValidateVATProdPostingGroup(sender: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if (sender."VAT Bus. Posting Group" = '') and (sender."VAT Prod. Posting Group" = '') then
            IsHandled := true;
    end;
}