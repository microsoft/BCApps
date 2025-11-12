namespace System.Environment.Configuration;

using System;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;
using System.Tooling;

page 9200 "Personalized Pages"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Personalized Pages';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "User Page Metadata";
    UsageCategory = Lists;
    AdditionalSearchTerms = 'delete user personalization,User Page Personalizations,User Page Personalization List';

    layout
    {
        area(content)
        {
            repeater(Personalizations)
            {
                ShowCaption = false;
                field("User SID"; Rec."User SID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User SID';
                    ToolTip = 'Specifies the security identifier (SID) of the user who did the personalization.';
                    Visible = false;
                }
                field("User ID"; CurrentUserName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Name';
                    ToolTip = 'Specifies the user name of the user who performed the personalization.';
                    Editable = false;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page ID';
                    ToolTip = 'Specifies the number of the page object that has been personalized.';
                }
                field(PageCaption; PageName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page Caption';
                    ToolTip = 'Specifies the caption of the page that has been personalized.';
                }
                field(LastModified; Rec.SystemModifiedAt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Modified';
                    ToolTip = 'Specifies the date of the personalization.';
                    Editable = false;
                }
                field(Health; HealthStatus)
                {
                    Caption = 'Health';
                    ApplicationArea = Basic, Suite;
                    StyleExpr = HealthStatusStyleExpr;
                    ToolTip = 'Specifies whether any issues were found with the personalization when diagnostic tests were last run.';
                    Visible = ShowUserDiagnosticsListPart;
                }
            }

            part(UserDiagnosticsListPart; "Designer Diagnostics ListPart")
            {
                Caption = 'Detected Issues';
                ApplicationArea = Basic, Suite;
                Visible = ShowUserDiagnosticsListPart;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TroubleshootIssues)
            {
                Caption = 'Troubleshoot';
                ApplicationArea = All;
                Image = Troubleshoot;
                ToolTip = 'Runs a series of diagnostic tests on the list of personalizations.';

                trigger OnAction()
                begin
                    ValidatePages();
                    ShowScanCompleteMessage();
                    ShowUserDiagnosticsListPart := true;
                    UpdateUserDiagnosticsListPart();
                end;
            }

            action(ShowErrorsAction)
            {
                Caption = 'Show only errors';
                ApplicationArea = All;
                Visible = ShowUserDiagnosticsListPart and (not ShowingOnlyErrors);
                Image = Filter;
                ToolTip = 'Filter on only page customizations with errors.';

                trigger OnAction()
                var
                    OperationId: Guid;
                begin
                    ShowingOnlyErrors := true;
                    TempDesignerDiagnostics.Reset();
                    TempDesignerDiagnostics.SetRange(Severity, Enum::Severity::Error);

                    if Rec.FindSet() then
                        repeat
                            if UserSidToOperationId.Get(Format(Rec."User SID") + Format(Rec."Page ID"), OperationId) then begin
                                TempDesignerDiagnostics.SetRange("Operation ID", OperationId);
                                if not TempDesignerDiagnostics.IsEmpty() then
                                    Rec.Mark(true);
                            end;
                        until Rec.Next() = 0;
                    Rec.MarkedOnly(true);
                    UpdateUserDiagnosticsListPart();
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
                    UpdateUserDiagnosticsListPart();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(TroubleshootIssues_Promoted; TroubleshootIssues)
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

    trigger OnAfterGetRecord()
    var
        PageMetadata: Record "Page Metadata";
    begin
        if PageMetadata.Get(Rec."Page ID") then
            PageName := PageMetadata.Caption
        else
            PageName := '';

        CurrentUserName := UserSidToUserName(Rec."User SID");

        HealthStatus := CreatePageDiagnosticsMessageAndSetStyleExpr();
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();

        PrivacyFilterUserPersonalizations();
        if not IsNullGuid(FilterUserID) then
            Rec.SetRange("User SID", FilterUserID)
        else
            Rec.SetFilter("User SID", GenerateUserSidFilter());
    end;

    /// <summary>
    /// Ensure that users can only see their own personalizations, unless they have the permission to manage users on the tenant.
    /// </summary>
    local procedure PrivacyFilterUserPersonalizations()
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        if UserPermissions.CanManageUsersOnTenant(UserSecurityId()) then
            exit; // No need for additional user filters

        Rec.FilterGroup(2);
        Rec.SetRange("User SID", UserSecurityId());
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateUserDiagnosticsListPart();
    end;

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

    local procedure GenerateUserSidFilter() UserSidFilter: Text
    var
        User: Record User;
        UserSelection: Codeunit "User Selection";
    begin
        UserSidFilter := UserSecurityId();

        UserSelection.HideExternalUsers(User);

        if User.FindSet() then
            repeat
                UserSidFilter += '|' + User."User Security ID";
            until User.Next() = 0
    end;

    local procedure CountNumberOfUsersWithinFilter(var UserPageMetadata: Record "User Page Metadata") TotalUsers: Integer
    var
        LocalUserPageMetadata: Record "User Page Metadata";
        CurrentUserId: Guid;
    begin
        LocalUserPageMetadata.CopyFilters(UserPageMetadata);

        if LocalUserPageMetadata.FindSet() then begin
            CurrentUserId := LocalUserPageMetadata."User SID"; // First user may have empty guid, hence we need to especially take care of that one
            TotalUsers += 1;
            repeat
                if CurrentUserId <> LocalUserPageMetadata."User SID" then begin
                    CurrentUserId := LocalUserPageMetadata."User SID";
                    TotalUsers += 1;
                end;
            until LocalUserPageMetadata.Next() = 0;
        end;
    end;

    local procedure ValidatePages()
    var
        NavDesignerPersonalizationPageCustomizationValidation: DotNet NavDesignerPersonalizationPageCustomizationValidation;
        ValidationProgressDialog: Dialog;
        TotalUsers: Integer;
        CurrentUserNumber: Integer;
        CurrentUserId: Guid;
    begin
        Rec.SetCurrentKey("User SID");
        Rec.SetAscending("User SID", true);
        TotalUsers := CountNumberOfUsersWithinFilter(Rec);

        CurrentUserNumber := 0;
        if Rec.FindSet() then
            repeat
                // We may have multiple profiles in this query, every time we see a new profile, we need to re-create the NavDesignerConfigurationPageCustomizationValidation for that profile
                if (CurrentUserId <> Rec."User SID") or IsNull(NavDesignerPersonalizationPageCustomizationValidation) then begin
                    NavDesignerPersonalizationPageCustomizationValidation := NavDesignerPersonalizationPageCustomizationValidation.Create(Rec."User SID");
                    CurrentUserId := Rec."User SID";
                    ValidationProgressDialog.Open(StrSubstNo(ValidatePageTxt, UserSidToUserName(Rec."User SID"), CurrentUserNumber, TotalUsers));
                    CurrentUserNumber += 1;
                end;

                ValidatePageForDesignerCustomizationBase(NavDesignerPersonalizationPageCustomizationValidation, Rec);
            until Rec.Next() = 0;
    end;

    local procedure ValidatePageForDesignerCustomizationBase(NavDesignerPageCustomizationValidationBase: dotnet NavDesignerPageCustomizationValidationBase; UserPageMetadata: Record "User Page Metadata")
    var
        NavDesignerCompilationResult: dotnet NavDesignerCompilationResult;
        NavDesignerDiagnostic: DotNet NavDesignerDiagnostic;
        OperationId: Guid;
    begin
        // Validate page customization
        NavDesignerCompilationResult := NavDesignerPageCustomizationValidationBase.ValidatePageCustomization(UserPageMetadata."Page ID");

        OperationId := CreateGuid();
        TempDesignerDiagnostics."Operation ID" := OperationId;
        foreach NavDesignerDiagnostic in NavDesignerCompilationResult.Diagnostics() do begin
            TempDesignerDiagnostics."Diagnostics ID" += 1;
            TempDesignerDiagnostics.Severity := TempDesignerDiagnostics.ConvertNavDesignerDiagnosticSeverityToEnum(NavDesignerDiagnostic.Severity());
            TempDesignerDiagnostics.Message := CopyStr(NavDesignerDiagnostic.Message(), 1, MaxStrLen(TempDesignerDiagnostics.Message));
            TempDesignerDiagnostics.Insert();
        end;

        // Add mapping to page diagnostics
        UserSidToOperationId.Set(Format(UserPageMetadata."User SID") + Format(UserPageMetadata."Page ID"), OperationId);
    end;

    local procedure CreatePageDiagnosticsMessageAndSetStyleExpr(): Text
    var
        OperationId: Guid;
    begin
        HealthStatusStyleExpr := 'Favorable';

        if not UserSidToOperationId.Get(Format(Rec."User SID") + Format(Rec."Page ID"), OperationId) then
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

    local procedure UserSidToUserName(UserSid: Guid): Code[50]
    var
        User: Record User;
    begin
        if UserSid = UserSecurityId() then
            exit(CopyStr(UserId(), 1, 50)); // Covers the case of empty user table

        if User.ReadPermission() then
            if User.Get(UserSid) then
                exit(User."User Name");

        exit(UserSid);
    end;

    local procedure UpdateUserDiagnosticsListPart()
    var
        OperationId: Guid;
    begin
        if UserSidToOperationId.Get(Format(Rec."User SID") + Format(Rec."Page ID"), OperationId) then;
        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.SetRange("Operation ID", OperationId);
        CurrPage.UserDiagnosticsListPart.Page.SetRecords(TempDesignerDiagnostics);
        CurrPage.UserDiagnosticsListPart.Page.Update(false);
    end;

    procedure SetUserID(UserID: Guid)
    begin
        FilterUserID := UserID;
    end;

    var
        TempDesignerDiagnostics: Record "Designer Diagnostic" temporary;
        ValidatePageTxt: Label 'Scanning page personalizations for %1\%2 of %3 users scanned', Comment = '%1 = user id, %2 and %3 are all whole numbers';
        PageValidationFailedWithErrorsTxt: Label '%1 error(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedWithWarningsTxt: Label '%1 warning(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedWithInformationalMessagesTxt: Label '%1 informational message(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedTxt: Label 'OK';
        ScanCompletedWithErrorsMsg: Label 'Scanning complete, %1 error(s) were found.', Comment = '%1 = a number from 1 and up';
        ScanCompletedSuccessfullyMsg: Label 'Scanning complete, no issues were found.';
        HealthStatusStyleExpr: Text;
        HealthStatus: Text;
        UserSidToOperationId: Dictionary of [Text, Guid];
        ShowUserDiagnosticsListPart: Boolean;
        PageName: Text;
        CurrentUserName: Text;
        FilterUserID: Guid;
        ShowingOnlyErrors: Boolean;
}

