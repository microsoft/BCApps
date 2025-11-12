namespace System.Azure.Identity;

page 6301 "Azure AD App Setup Part"
{
    Caption = '<Microsoft Entra application Setup Part>';
    PageType = CardPart;
    SourceTable = "Azure AD App Setup";

    layout
    {
        area(content)
        {
            field(HomePageUrl; HomePageUrl)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Home page URL';
                Editable = false;
                ToolTip = 'Specifies the home page URL to enter when registering a Microsoft Entra application.';
            }
            field(RedirectUrl; RedirectUrl)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reply URL';
                ToolTip = 'Specifies the reply URL to enter when registering a Microsoft Entra application.';
            }
            field(AppId; AppId)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Application ID';
                ShowMandatory = true;
                ToolTip = 'Specifies the ID that is assigned to the application when it is registered in Microsoft Entra ID. The ID is used for authenticating with Microsoft Entra ID. This is also referred to as the client ID.';
            }
            field(SecretKey; SecretKey)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Key';
                NotBlank = true;
                ShowMandatory = true;
                ToolTip = 'Specifies the secret key (or client secret) that is used along with the Application ID for authenticating with Microsoft Entra ID.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
    begin
        if not Rec.FindFirst() then
            Rec.Init();

        HomePageUrl := GetUrl(CLIENTTYPE::Web);
        RedirectUrl := AzureADMgt.GetRedirectUrl();
        AppId := Rec."App ID";
        SetSecretKeyGlobalFromIsolatedStorage();
    end;

    var
        HomePageUrl: Text;
        RedirectUrl: Text[150];
        [NonDebuggable]
        SecretKey: Text;
        AppId: Guid;
        InvalidAppIdErr: Label 'Enter valid GUID for Application ID.';
        InvalidClientSecretErr: Label 'Key is required.';

    [NonDebuggable]
    local procedure SetSecretKeyGlobalFromIsolatedStorage()
    begin
        SecretKey := Rec.GetSecretKeyFromIsolatedStorageAsSecretText().Unwrap();
    end;

    [NonDebuggable]
    procedure Save()
    var
        SecretKeyText: SecretText;
    begin
        SecretKeyText := SecretKey;
        Rec."Redirect URL" := RedirectUrl;
        Rec."App ID" := AppId;
        Rec.SetSecretKeyToIsolatedStorage(SecretKeyText);

        if not Rec.Modify(true) then
            Rec.Insert(true);
    end;

    procedure ValidateFields()
    begin
        if IsNullGuid(AppId) then
            Error(InvalidAppIdErr);

        if SecretKey = '' then
            Error(InvalidClientSecretErr);
    end;

    [Scope('OnPrem')]
    procedure SetReplyURLWithDefault()
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
    begin
        RedirectUrl := AzureADMgt.GetDefaultRedirectUrl();
    end;
#if not CLEAN25

    [NonDebuggable]
    [Obsolete('Replaced by SetAppDetails(ApplicationId: Guid; "Key": SecretText)', '25.0')]
    procedure SetAppDetails(ApplicationId: Guid; "Key": Text)
    var
        KeyAsSecretText: SecretText;
    begin
        KeyAsSecretText := Key;
        SetAppDetails(ApplicationId, KeyAsSecretText);
    end;
#endif

    [NonDebuggable]
    procedure SetAppDetails(ApplicationId: Guid; "Key": SecretText)
    begin
        AppId := ApplicationId;
        SecretKey := Key.Unwrap();
    end;

    procedure GetRedirectUrl(): Text
    begin
        exit(RedirectUrl);
    end;
}

