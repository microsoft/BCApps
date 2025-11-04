tableextension 20400 "Qlty. Mgmt. Setup - Mfg" extends "Qlty. Management Setup"
{
    fields
    {
        field(10; "Production Trigger"; Enum "Qlty. Production Trigger")
        {
            Description = 'Optionally choose a production related trigger to try and create a test.';
            Caption = 'Production Trigger';
            ToolTip = 'Specifies a default production-related trigger value for Test Generation Rules to try and create a test.';

            trigger OnValidate()
            var
                QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
            begin
                if (Rec."Production Trigger" <> xRec."Production Trigger") and (xRec."Production Trigger" <> xRec."Production Trigger"::NoTrigger) then begin
                    QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Production);
                    QltyInTestGenerationRule.SetRange("Production Trigger", xRec."Production Trigger");
                    if (not QltyInTestGenerationRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesMfgQst, QltyInTestGenerationRule.Count(), xRec."Production Trigger", Rec."Production Trigger")) then
                            QltyInTestGenerationRule.ModifyAll("Production Trigger", Rec."Production Trigger", false);
                end;
            end;
        }
        field(11; "Production Update Control"; Enum "Qlty. Update Source Behavior")
        {
            Description = 'Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Production Order changes status to Finished). Set to "Do Not Update" to prevent updating the original source that created the test.';
            InitValue = "Do not update";
            Caption = 'Production Update Control';
            ToolTip = 'Specifies whether to update when the source changes. Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Production Order changes status to Finished). Set to "Do Not Update" to prevent updating the original source that created the test.';
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
        ConfirmExistingRulesMfgQst: Label 'You have %1 existing generation rules that used the "%2" setting. Do you want to change those to be "%3"?', Comment = '%1=the count, %2=the old setting, %3=the new setting.';
}
