namespace System.Environment.Configuration;

using System.Apps;

page 9197 "Profile Designer Diagnostics"
{
    PageType = ListPart;
    Caption = 'Profile Designer Diagnostics';
    SourceTable = "Profile Designer Diagnostic";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("Profile ID"; Rec."Profile ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies an ID that is used to identify the profile (role). There can be more than one profile with the same ID if they come from different extensions.';
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Indicates whether adding or replacing the profile was successful. Choose the link for more details.';

                    trigger OnDrillDown()
                    var
                        ProfileDesignerDiagnosticForProfile: Record "Profile Designer Diagnostic";
                    begin
                        ProfileDesignerDiagnosticForProfile.SetRange("Import ID", Rec."Import ID");
                        ProfileDesignerDiagnosticForProfile.SetRange("Profile App ID", Rec."Profile App ID");
                        ProfileDesignerDiagnosticForProfile.SetRange("Profile ID", Rec."Profile ID");
                        ProfileDesignerDiagnosticForProfile.SetFilter(Severity, '<>%1', ProfileDesignerDiagnosticForProfile.Severity::Hidden);
                        if not ProfileDesignerDiagnosticForProfile.IsEmpty() then
                            Page.Run(Page::"Profile Import Result List", ProfileDesignerDiagnosticForProfile);
                    end;
                }
                field(ApplicationNameField; ApplicationName)
                {
                    Caption = 'Source';
                    Editable = false;
                    Visible = false; // Too much clutter to show by default but allow admin to show this if necessary to distinguish between profiles
                    ApplicationArea = All;
                    ToolTip = 'Specifies the origin of this profile, which can be either an extension, shown by its name, or a custom profile created by a user.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ApplicationName := ExtensionManagement.GetAppName(Rec."Profile App ID");
    end;

    procedure SetRecords(ImportID: Guid)
    var
        ProfileDesignerDiagnostic: record "Profile Designer Diagnostic";
        ProfileDesignerDiagnosticCounter: record "Profile Designer Diagnostic";
        PreviousAppId: Guid;
        PreviousProfileId: Code[30];
        NumErrors: Integer;
        NumWarnings: Integer;
        NumInformation: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        ProfileDesignerDiagnostic.SetRange("Import ID", ImportID);
        ProfileDesignerDiagnosticCounter.SetRange("Import ID", ImportID);
        PreviousProfileId := '';
        if ProfileDesignerDiagnostic.FindSet() then
            repeat
                if ((ProfileDesignerDiagnostic."Profile App ID" <> PreviousAppId) or (ProfileDesignerDiagnostic."Profile ID" <> PreviousProfileId)) then begin
                    // Insert an entry for every unique profile and calculate the message to show based on diagnostic messages
                    PreviousAppId := ProfileDesignerDiagnostic."Profile App ID";
                    PreviousProfileId := ProfileDesignerDiagnostic."Profile ID";
                    ProfileDesignerDiagnosticCounter.SetRange("Profile App ID", ProfileDesignerDiagnostic."Profile App ID");
                    ProfileDesignerDiagnosticCounter.SetRange("Profile ID", ProfileDesignerDiagnostic."Profile ID");
                    ProfileDesignerDiagnosticCounter.SetRange(Severity, ProfileDesignerDiagnosticCounter.Severity::Error);
                    NumErrors := ProfileDesignerDiagnosticCounter.Count();
                    ProfileDesignerDiagnosticCounter.SetRange(Severity, ProfileDesignerDiagnosticCounter.Severity::Warning);
                    NumWarnings := ProfileDesignerDiagnosticCounter.Count();
                    ProfileDesignerDiagnosticCounter.SetRange(Severity, ProfileDesignerDiagnosticCounter.Severity::Information);
                    NumInformation := ProfileDesignerDiagnosticCounter.Count();

                    Rec := ProfileDesignerDiagnostic;
                    Rec.Message := CreateImportDiagnosticsMessage(NumErrors, NumWarnings, NumInformation);
                    Rec.Insert();
                end;
            until ProfileDesignerDiagnostic.Next() = 0;
    end;

    local procedure CreateImportDiagnosticsMessage(NumErrors: Integer; NumWarnings: Integer; NumInformation: Integer): Text[2048]
    begin
        if NumErrors > 0 then
            exit(ImportFailedTxt);
        if NumWarnings > 0 then
            exit(ImportSuccessWithWarningsTxt);
        if NumInformation > 0 then
            exit(ImportSuccessWithInfoTxt);
        exit(ImportSuccessTxt);
    end;

    var
        ExtensionManagement: Codeunit "Extension Management";
        ApplicationName: Text;
        ImportSuccessTxt: Label 'Successfully imported';
        ImportSuccessWithWarningsTxt: Label 'Successfully imported with warnings';
        ImportSuccessWithInfoTxt: Label 'Successfully imported with informational messages';
        ImportFailedTxt: Label 'Import failed';
}
