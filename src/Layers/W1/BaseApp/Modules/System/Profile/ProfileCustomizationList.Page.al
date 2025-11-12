namespace System.Environment.Configuration;

using System;
using System.Reflection;
using System.Tooling;

page 9190 "Profile Customization List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customized Pages';
    Extensible = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    UsageCategory = Lists;
    SourceTable = "All Profile Page Metadata";
    AdditionalSearchTerms = 'Page customizations,Profile configurations,Profile customizations,Role customizations';

    layout
    {
        area(content)
        {
            repeater(Repeater1)
            {
                ShowCaption = false;
                field("Profile ID"; Rec."Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile ID';
                    ToolTip = 'Specifies the profile that the customization has been created for.';
                }
                field("App ID"; Rec."Profile App ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile App ID';
                    ToolTip = 'Specifies the ID of the app that provided the profile that this page customization applies to.';
                    Visible = false;
                    Editable = false;
                }
                field("App Name"; Rec."Profile App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile Source';
                    ToolTip = 'Specifies the origin of the profile that this page customization applies to, which can be either an extension, shown by its name, or a custom profile created by a user.';
                    Visible = false;
                    Editable = false;
                }
                field(PageIdField; Rec."Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page ID';
                    ToolTip = 'Specifies the number of the page object that has been customized.';
                    Lookup = false;
                }
                field(PageCaptionField; PageCaptionText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page Caption';
                    ToolTip = 'Specifies the caption of the page object that has been customized.';
                    Editable = false;
                }
                field(OwnerField; Owner)
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = 'Tenant,System';
                    Caption = 'Owner';
                    ToolTip = 'Specifies whether the customization was made by a user (Tenant) or provided as part of an extension (System).';
                    Visible = false;
                    Editable = false;
                }
                field("Cust App Name"; Rec."App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page Customization Source';
                    ToolTip = 'Specifies the name of the app that defines this page customization.';
                    Editable = false;
                }
                field(Health; HealthStatus)
                {
                    Caption = 'Health';
                    ApplicationArea = Basic, Suite;
                    StyleExpr = HealthStatusStyleExpr;
                    ToolTip = 'Specifies whether any problems were found with the customization when diagnostic tests were last run.';
                    Visible = ShowProfileDiagnosticsListPart;
                    Editable = false;
                }
            }

            part(ProfileDiagnosticsListPart; "Designer Diagnostics ListPart")
            {
                Caption = 'Detected Problems';
                ApplicationArea = Basic, Suite;
                Visible = ShowProfileDiagnosticsListPart;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TroubleshootProblems)
            {
                Caption = 'Troubleshoot';
                ApplicationArea = All;
                Image = Troubleshoot;
                ToolTip = 'Runs a series of diagnostic tests on the list of customizations.';

                trigger OnAction()
                begin
                    ValidatePages();
                    ShowScanCompleteMessage();
                    ShowProfileDiagnosticsListPart := true;
                end;
            }

            action(ShowErrorsAction)
            {
                Caption = 'Show only errors';
                ApplicationArea = All;
                Visible = ShowProfileDiagnosticsListPart and (not ShowingOnlyErrors);
                Image = Filter;
                ToolTip = 'Filter on only page customizations with errors.';

                trigger OnAction()
                var
                    AllProfilePageMetadata: Record "All Profile Page Metadata";
                    OperationId: Guid;
                begin
                    ShowingOnlyErrors := true;
                    TempDesignerDiagnostics.Reset();
                    TempDesignerDiagnostics.SetRange(Severity, Enum::Severity::Error);

                    AllProfilePageMetadata.CopyFilters(Rec);
                    if AllProfilePageMetadata.FindSet() then
                        repeat
                            if SystemIdToOperationId.Get(AllProfilePageMetadata.SystemId, OperationId) then begin
                                TempDesignerDiagnostics.SetRange("Operation ID", OperationId);
                                if not TempDesignerDiagnostics.IsEmpty() then
                                    AllProfilePageMetadata.Mark(true);
                            end;
                        until AllProfilePageMetadata.Next() = 0;

                    AllProfilePageMetadata.MarkedOnly(true);
                    CurrPage.SetTableView(AllProfilePageMetadata);
                    UpdateProfileDiagnosticsListPart();
                end;
            }

            action(ShowAllPagesAction)
            {
                Caption = 'Show all';
                ApplicationArea = All;
                Visible = ShowingOnlyErrors;
                Image = Filter;
                ToolTip = 'Show all page customizations within filter.';

                trigger OnAction()
                begin
                    Rec.ClearMarks();
                    Rec.MarkedOnly(false);
                    ShowingOnlyErrors := false;
                    if Rec.FindFirst() then;
                    UpdateProfileDiagnosticsListPart();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(TroubleshootProblems_Promoted; TroubleshootProblems)
                {
                }
                actionref(ShowErrorsAction_Promoted; ShowErrorsAction)
                {
                }
                actionref(ShowAllPagesAction_Promoted; ShowAllPagesAction)
                {
                }
            }
        }
    }

    local procedure ShowScanCompleteMessage()
    var
        Errors: Integer;
    begin
        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.SetRange(Severity, Enum::Severity::Error);
        Errors := TempDesignerDiagnostics.Count();

        if Errors > 0 then
            Message(ScanCompletedWithErrorsMsg, Errors)
        else
            Message(ScanCompletedSuccessfullyMsg);
    end;

    local procedure CountNumberOfProfilesWithinFilter(var AllProfilePageMetadata: Record "All Profile Page Metadata") TotalProfiles: Integer
    var
        CurrentProfileId: Code[30];
        CurrentProfileAppId: Guid;
    begin
        if AllProfilePageMetadata.FindSet() then
            repeat
                if (CurrentProfileId <> AllProfilePageMetadata."Profile ID") or (CurrentProfileAppId <> AllProfilePageMetadata."Profile App ID") then begin
                    CurrentProfileId := AllProfilePageMetadata."Profile ID";
                    CurrentProfileAppId := AllProfilePageMetadata."Profile App ID";
                    TotalProfiles += 1;
                end;
            until AllProfilePageMetadata.Next() = 0;
    end;

    local procedure ValidatePages()
    var
        AllProfilePageMetadata: Record "All Profile Page Metadata";
        NavDesignerConfigurationPageCustomizationValidation: DotNet NavDesignerConfigurationPageCustomizationValidation;
        ValidationProgressDialog: Dialog;
        TotalProfiles: Integer;
        CurrentProfileNumber: Integer;
        CurrentProfileId: Code[30];
        CurrentProfileAppId: Guid;
        EmptyGuid: Guid;
    begin
        TotalProfiles := Rec.Count();
        AllProfilePageMetadata.CopyFilters(Rec);
        AllProfilePageMetadata.SetCurrentKey("Profile App ID", "Profile ID");
        AllProfilePageMetadata.SetAscending("Profile App ID", true);
        AllProfilePageMetadata.SetAscending("Profile ID", true);
        AllProfilePageMetadata.SetRange("App ID", EmptyGuid); // We can only scan user created page customizations
        TotalProfiles := CountNumberOfProfilesWithinFilter(AllProfilePageMetadata);

        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.DeleteAll();

        if AllProfilePageMetadata.FindSet() then
            repeat
                // We may have multiple profiles in this query, every time we see a new profile, we need to re-create the NavDesignerConfigurationPageCustomizationValidation for that profile
                if (CurrentProfileId <> AllProfilePageMetadata."Profile ID") or (CurrentProfileAppId <> AllProfilePageMetadata."Profile App ID") then begin
                    NavDesignerConfigurationPageCustomizationValidation := NavDesignerConfigurationPageCustomizationValidation.Create(AllProfilePageMetadata."Profile ID", AllProfilePageMetadata."Profile App ID");
                    CurrentProfileId := AllProfilePageMetadata."Profile ID";
                    CurrentProfileAppId := AllProfilePageMetadata."Profile App ID";
                    ValidationProgressDialog.Open(StrSubstNo(ValidatePageTxt, AllProfilePageMetadata."Profile ID", CurrentProfileNumber, TotalProfiles));
                    CurrentProfileNumber += 1;
                end;

                ValidatePageForDesignerCustomizationBase(NavDesignerConfigurationPageCustomizationValidation, AllProfilePageMetadata);
            until AllProfilePageMetadata.Next() = 0;
    end;

    local procedure ValidatePageForDesignerCustomizationBase(NavDesignerPageCustomizationValidationBase: dotnet NavDesignerPageCustomizationValidationBase; AllProfilePageMetadata: record "All Profile Page Metadata")
    var
        NavDesignerCompilationResult: dotnet NavDesignerCompilationResult;
        NavDesignerDiagnostic: DotNet NavDesignerDiagnostic;
        OperationId: Guid;
    begin
        // Validate page customization
        NavDesignerCompilationResult := NavDesignerPageCustomizationValidationBase.ValidatePageCustomization(AllProfilePageMetadata."Page ID");

        OperationId := CreateGuid();
        TempDesignerDiagnostics."Operation ID" := OperationId;
        foreach NavDesignerDiagnostic in NavDesignerCompilationResult.Diagnostics() do begin
            TempDesignerDiagnostics."Diagnostics ID" += 1;
            TempDesignerDiagnostics.Severity := TempDesignerDiagnostics.ConvertNavDesignerDiagnosticSeverityToEnum(NavDesignerDiagnostic.Severity());
            TempDesignerDiagnostics.Message := CopyStr(NavDesignerDiagnostic.Message(), 1, MaxStrLen(TempDesignerDiagnostics.Message));
            TempDesignerDiagnostics.Insert();
        end;

        // Add mapping to page diagnostics
        SystemIdToOperationId.Set(AllProfilePageMetadata.SystemId, OperationId);
    end;

    local procedure CreatePageDiagnosticsMessageAndSetStyleExpr(): Text
    var
        OperationId: Guid;
    begin
        HealthStatusStyleExpr := 'Favorable';
        if (not IsNullGuid(Rec."App ID")) then
            exit(CustomizationFromExtensionCannotBeScannedTxt);

        if not SystemIdToOperationId.Get(Rec.SystemId, OperationId) then
            exit;

        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.SetRange("Operation ID", OperationId);
        TempDesignerDiagnostics.SetRange(Severity, Enum::Severity::Error);
        if TempDesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Unfavorable';
            exit(StrSubstNo(PageValidationFailedWithErrorsTxt, TempDesignerDiagnostics.Count()));
        end;
        TempDesignerDiagnostics.SetRange(Severity, Enum::Severity::Warning);
        if TempDesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Ambiguous';
            exit(StrSubstNo(PageSuccessfullyValidatedWithWarningsTxt, TempDesignerDiagnostics.Count()));
        end;
        TempDesignerDiagnostics.SetRange(Severity, Enum::Severity::Information);
        if TempDesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Favorable';
            exit(StrSubstNo(PageSuccessfullyValidatedWithInformationalMessagesTxt, TempDesignerDiagnostics.Count()));
        end;
        exit(PageSuccessfullyValidatedTxt)
    end;

    trigger OnAfterGetRecord()
    var
        PageMetadata: Record "Page Metadata";
    begin
        if PageMetadata.Get(Rec."Page ID") then
            PageCaptionText := PageMetadata.Caption
        else
            PageCaptionText := StrSubstNo(PageTxt, Rec."Page ID");

        if IsNullGuid(Rec."App ID") then
            Owner := Owner::Tenant
        else
            Owner := Owner::System;

        HealthStatus := CreatePageDiagnosticsMessageAndSetStyleExpr();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateProfileDiagnosticsListPart();
    end;

    local procedure UpdateProfileDiagnosticsListPart()
    var
        OperationId: Guid;
    begin
        if SystemIdToOperationId.Get(Rec.SystemId, OperationId) then;
        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.SetRange("Operation ID", OperationId);
        CurrPage.ProfileDiagnosticsListPart.Page.SetRecords(TempDesignerDiagnostics);
        CurrPage.ProfileDiagnosticsListPart.Page.Update(false);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if (not IsNullGuid(Rec."App ID")) then
            Error(CannotDeleteExtensionProfileErr);
    end;

    var
        TempDesignerDiagnostics: Record "Designer Diagnostic" temporary;
        CannotDeleteExtensionProfileErr: Label 'You cannot delete this profile customization because it comes from an extension.';
        PageCaptionText: Text;
        ValidatePageTxt: Label 'Scanning page customizations for %1\%2 of %3 profiles scanned', Comment = '%1 = profile id, %2 and %3 are all whole numbers';
        PageTxt: Label 'Page %1', Comment = '%1 is a whole number, ex. 10';
        PageValidationFailedWithErrorsTxt: Label '%1 error(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedWithWarningsTxt: Label '%1 warning(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedWithInformationalMessagesTxt: Label '%1 informational message(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedTxt: Label 'OK';
        ScanCompletedWithErrorsMsg: Label 'Scanning complete, %1 error(s) were found.', Comment = '%1 = a number from 1 and up';
        ScanCompletedSuccessfullyMsg: Label 'Scanning complete, no problems were found.';
        CustomizationFromExtensionCannotBeScannedTxt: Label 'Customization provided by extension cannot be scanned.';
        HealthStatusStyleExpr: Text;
        HealthStatus: Text;
        SystemIdToOperationId: Dictionary of [Guid, Guid];
        ShowProfileDiagnosticsListPart: Boolean;
        ShowingOnlyErrors: Boolean;
        Owner: Option Tenant,System;
}

