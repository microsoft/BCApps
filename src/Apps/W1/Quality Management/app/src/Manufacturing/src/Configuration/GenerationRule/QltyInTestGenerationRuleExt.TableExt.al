tableextension 20401 "Qlty. In. Test Gen. Rule - Mfg" extends "Qlty. In. Test Generation Rule"
{
    fields
    {
        field(26; "Production Trigger"; Enum "Qlty. Production Trigger")
        {
            Caption = 'Production Trigger';
            ToolTip = 'Specifies whether the generation rule should be used to automatically create tests based on a production trigger.';

            trigger OnValidate()
            var
                QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
            begin
                Rec.ConfirmUpdateManualTriggerStatus();
                if (Rec."Activation Trigger" = Rec."Activation Trigger"::Disabled) and (Rec."Template Code" <> '') and (Rec."Production Trigger" <> Rec."Production Trigger"::NoTrigger) and GuiAllowed() then
                    QltyNotificationMgmt.Notify(StrSubstNo(RuleCurrentlyDisabledMfgLbl, Rec."Sort Order", Rec."Template Code", Rec."Production Trigger"));
            end;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        RuleCurrentlyDisabledMfgLbl: Label 'The generation rule Sort Order %1, Template Code %2 is currently disabled. It will need to have an activation trigger of "Automatic Only" or "Manual or Automatic" before it will be triggered by "%3"', Comment = '%1=generation rule sort order,%2=generation rule template code,%3=auto trigger';


}