codeunit 101994 "Create Profiles"
{

    trigger OnRun()
    var
        AllProfile: Record "All Profile";
    begin
        DemoDataSetup.Get();

        // Set Default Profile
        AllProfile.SetRange("Default Role Center", true);

        // Do not overwrite the default role center ID if one already exists
        // (Since these tables are not company specific)
        if AllProfile.IsEmpty() then begin
            Clear(AllProfile);
            AllProfile.SetRange("Role Center ID", GetDefaultRoleCenterForDataType(DemoDataSetup."Data Type"));
            if AllProfile.FindFirst() then begin
                AllProfile."Default Role Center" := true;
                AllProfile.Modify();
            end;
        end;

        // Disable personalization from invoicing role center
        Clear(AllProfile);
        AllProfile.Init();
        AllProfile.SetRange("Profile ID", InvoicingProfileTxt);
        AllProfile.FindFirst();
        AllProfile."Disable Personalization" := true;
        AllProfile.Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        InvoicingProfileTxt: Label 'O365 Sales', Locked = true;

    local procedure GetDefaultRoleCenterForDataType(DataType: Option): Integer
    begin
        case DataType of
            DemoDataSetup."Data Type"::Extended:
                exit(Page::"Order Processor Role Center");
            DemoDataSetup."Data Type"::Standard,
            DemoDataSetup."Data Type"::Evaluation:
                exit(0); // Role center decided by the Plan overrides this values
        end;
    end;
}

