namespace System.Environment.Configuration;

using System.Reflection;

page 9175 "Copy Profile"
{
    Caption = 'Copy Profile';
    Editable = true;
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(Options)
            {
                group(SourceProfile)
                {
                    Caption = 'Source profile';

                    field(SourceProfileID; SourceAllProfile."Profile ID")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Profile ID';
                        ToolTip = 'Specifies the ID of the profile that you are copying.';
                        Editable = false;

                        trigger OnAssistEdit()
                        var
                            Roles: Page Roles;
                        begin
                            Roles.Initialize();
                            Roles.LookupMode(true);
                            if Roles.RunModal() = Action::LookupOK then
                                Roles.GetRecord(SourceAllProfile);
                        end;
                    }
                    field(SourceProfileAppName; SourceAllProfile."App Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source';
                        ToolTip = 'Specifies the extension that provides the profile that you are copying.';
                        Editable = false;

                    }
                    field(SourceProfileCaption; SourceAllProfile.Caption)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Display Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the organizational role that you are copying.';
                    }

                }

                group(DestinationProfile)
                {
                    Caption = 'New profile';

                    field(DestinationProfileID; TempDestinationAllProfile."Profile ID")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Profile ID';
                        ToolTip = 'Specifies the ID of the new profile that will be created.';
                        ShowMandatory = true;

                        trigger OnValidate()
                        var
                            AllProfile: Record "All Profile";
                        begin
                            AllProfile.SetRange("Profile ID", TempDestinationAllProfile."Profile ID");
                            if not AllProfile.IsEmpty() then
                                Error(ProfileIdAlreadyExistErr, TempDestinationAllProfile."Profile ID");
                        end;
                    }
                    field(DestinationProfileCaption; TempDestinationAllProfile.Caption)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Display Name';
                        ToolTip = 'Specifies the name of the organizational role that will be created.';
                        ShowMandatory = true;
                    }
                }
            }
        }
    }

    procedure SetSourceAllProfile(AllProfile: Record "All Profile")
    begin
        SourceAllProfile := AllProfile;
    end;

    procedure GetDestinationAllProfile(var AllProfile: Record "All Profile")
    begin
        AllProfile := OutputAllProfile;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Clear(OutputAllProfile);
        if not (CloseAction in [Action::OK, Action::LookupOK]) then
            exit(true);

        TempDestinationAllProfile.TestField("Profile ID");
        TempDestinationAllProfile.TestField(Caption);

        SourceAllProfile.TestField("Profile ID");

        ConfPersonalizationMgt.CopyProfile(
            SourceAllProfile,
            TempDestinationAllProfile."Profile ID",
            TempDestinationAllProfile.Caption,
            OutputAllProfile);
    end;

    var
        SourceAllProfile: Record "All Profile";
        TempDestinationAllProfile: Record "All Profile" temporary; // Used only to display fields in the page
        OutputAllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
#pragma warning disable AA0470
        ProfileIdAlreadyExistErr: Label 'A profile with Profile ID "%1" already exist, please provide another Profile ID.';
#pragma warning restore AA0470
}




